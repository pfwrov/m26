#include <SDL.h>
#include <cmath>
#include <utility>

#include <m26/m26_controller.hpp>

struct Controller::Impl
{
  ControllerConfig config{};

  SDL_GameController *controller = nullptr;

  float lx = 0.F, ly = 0.F, rx = 0.F, ry = 0.F;
  float lt = 0.F, rt = 0.F;

  bool a = false, b = false, x = false, y = false;
  bool lb = false, rb = false, start = false, back = false;

  bool killed = true;
  bool armed = false;
  bool precision = false;
  bool prev_start = false;

  std::uint32_t last_input_ms = 0;

  ROVCommand cmd{};

  static float clamp(float val, float min, float max) { return val < min ? min : (val > max ? max : val); }

  static float deadzone(float val, float deadzone)
  {
    float aval = std::fabs(val);
    if (aval <= deadzone) { return 0.F; }
    float adj = (aval - deadzone) / (1.F - deadzone);
    return std::copysign(adj, val);
  }


  static float expo(float val, float exp) { return (1.F - exp) * val + exp * val * val * val; }

  static float norm_axis(int16_t val)
  {
    if (val >= 0) return float(val) / 32767.F;
    return float(val) / 32768.F;
  }

  void open_first()
  {
    const int n_jstk = SDL_NumJoysticks();
    for (int i = 0; i < n_jstk; ++i) {
      if (static_cast<bool>(SDL_IsGameController(i))) {
        controller = SDL_GameControllerOpen(i);
        if (static_cast<bool>(controller)) { break; }
      }
    }
  }

  void close()
  {
    if (static_cast<bool>(controller)) {
      SDL_GameControllerClose(controller);
      controller = nullptr;
    }
  }

  void handle_event(const SDL_Event &e)
  {
    switch (e.type) {
    case SDL_CONTROLLERDEVICEADDED:
      if (!static_cast<bool>(controller)) { open_first(); }
      break;

    case SDL_CONTROLLERDEVICEREMOVED:
      close();
      killed = true;
      armed = false;
      break;

    case SDL_CONTROLLERAXISMOTION: {
      auto axis = static_cast<SDL_GameControllerAxis>(e.caxis.axis);
      int16_t val = e.caxis.value;

      if (axis == SDL_CONTROLLER_AXIS_LEFTX) { lx = norm_axis(val); }
      if (axis == SDL_CONTROLLER_AXIS_LEFTY) { ly = norm_axis(val); }
      if (axis == SDL_CONTROLLER_AXIS_RIGHTX) { rx = norm_axis(val); }
      if (axis == SDL_CONTROLLER_AXIS_RIGHTY) { ry = norm_axis(val); }

      if (axis == SDL_CONTROLLER_AXIS_TRIGGERLEFT) { lt = clamp((norm_axis(val) + 1.F) * 0.5F, 0.F, 1.F); }
      if (axis == SDL_CONTROLLER_AXIS_TRIGGERRIGHT) { rt = clamp((norm_axis(val) + 1.F) * 0.5F, 0.F, 1.F); }

      last_input_ms = SDL_GetTicks();
      break;
    }

    case SDL_CONTROLLERBUTTONDOWN:
    case SDL_CONTROLLERBUTTONUP: {
      bool down = (e.type == SDL_CONTROLLERBUTTONDOWN);
      auto btn = static_cast<SDL_GameControllerButton>(e.cbutton.button);

      if (btn == SDL_CONTROLLER_BUTTON_A) { a = down; }
      if (btn == SDL_CONTROLLER_BUTTON_B) { b = down; }
      if (btn == SDL_CONTROLLER_BUTTON_X) { x = down; }
      if (btn == SDL_CONTROLLER_BUTTON_Y) { y = down; }
      if (btn == SDL_CONTROLLER_BUTTON_LEFTSHOULDER) { lb = down; }
      if (btn == SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) { rb = down; }
      if (btn == SDL_CONTROLLER_BUTTON_START) { start = down; }
      if (btn == SDL_CONTROLLER_BUTTON_BACK) { back = down; }

      last_input_ms = SDL_GetTicks();
      break;
    }

    default:
      break;
    }
  }

  void update_cmd(std::uint32_t now)
  {
    bool timed_out = (now - last_input_ms) > config.timeout_ms;

    if (!static_cast<bool>(controller) || timed_out) {
      cmd = {};
      cmd.killed = true;
      cmd.armed = false;
      return;
    }

    if (b) {
      killed = true;
      armed = false;
    }

    if (a) {
      killed = false;
      armed = true;
    }

    if (start && !prev_start) { precision = !precision; }
    prev_start = start;

    if (!killed && a) { armed = true; }
    if (killed) { armed = false; }

    if (killed) {
      cmd = {};
      cmd.killed = true;
      cmd.armed = false;
      return;
    }

    float lx2 = expo(deadzone(lx, config.left_stick_deadzone), config.expo);
    float ly2 = expo(deadzone(ly, config.left_stick_deadzone), config.expo);
    float rx2 = expo(deadzone(rx, config.right_stick_deadzone), config.expo);
    float ry2 = expo(deadzone(ry, config.right_stick_deadzone), config.expo);

    float surge = -ly2;
    float sway = lx2;
    float yaw = rx2;
    float pitch = -ry2;
    float heave = (rt - lt);

    float roll = 0.F;
    if (rb) { roll += 1.F; }
    if (lb) { roll -= 1.F; }

    float scale = precision ? 0.35F : 1.0F;

    cmd.surge = clamp(surge * config.max_surge * scale, -1.F, 1.F);
    cmd.sway = clamp(sway * config.max_sway * scale, -1.F, 1.F);
    cmd.heave = clamp(heave * config.max_heave * scale, -1.F, 1.F);
    cmd.yaw = clamp(yaw * config.max_yaw * scale, -1.F, 1.F);
    cmd.pitch = clamp(pitch * config.max_pitch * scale, -1.F, 1.F);
    cmd.roll = clamp(roll * config.max_roll * scale, -1.F, 1.F);

    cmd.killed = false;
    cmd.armed = armed;
  }
};

Controller::Controller(const ControllerConfig &config) : impl_(new Impl{}) { impl_->config = config; }
Controller::~Controller()
{
  if (static_cast<bool>(impl_)) {
    impl_->close();
    delete impl_;
  }
}

Controller::Controller(Controller &&other) noexcept : impl_(std::exchange(other.impl_, nullptr)) {}
Controller &Controller::operator=(Controller &&other) noexcept
{
  if (this != &other) {
    this->~Controller();
    impl_ = std::exchange(other.impl_, nullptr);
  }
  return *this;
}

bool Controller::init()
{
  if (SDL_Init(SDL_INIT_GAMECONTROLLER | SDL_INIT_EVENTS) != 0) { return false; }
  SDL_Log("SDL_NumJoysticks = %d", SDL_NumJoysticks());
  for (int i = 0; i < SDL_NumJoysticks(); ++i) {
    SDL_Log("  joy[%d] name=%s isGameController=%d", i, SDL_JoystickNameForIndex(i), SDL_IsGameController(i));
  }
  SDL_LogSetAllPriority(SDL_LOG_PRIORITY_INFO);
  SDL_GameControllerEventState(SDL_ENABLE);

  impl_->open_first();
  impl_->last_input_ms = SDL_GetTicks();
  impl_->killed = true;
  impl_->armed = false;
  impl_->cmd = {};
  impl_->cmd.killed = true;
  impl_->cmd.armed = false;
  return true;
}

void Controller::tick()
{
  SDL_Event e;
  while (static_cast<bool>(SDL_PollEvent(&e))) { impl_->handle_event(e); }
  impl_->update_cmd(SDL_GetTicks());
}

const ROVCommand &Controller::command() const { return impl_->cmd; }
