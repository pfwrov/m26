#ifndef M26_CONTROLLER_HPP
#define M26_CONTROLLER_HPP

#include <cstdint>

struct ROVCommand
{
  // + forward, - backward
  float surge = 0.F;
  // + right, - left
  float sway = 0.F;
  // + up, - down
  float heave = 0.F;
  // + clockwise, - counter-clockwise
  float yaw = 0.F;
  // + pitch up, - pitch down
  float pitch = 0.F;
  // + roll right, - roll left
  float roll = 0.F;

  bool armed = false;
  bool killed = true;
};

struct ControllerConfig
{
  float right_stick_deadzone = 0.1F;
  float left_stick_deadzone = 0.1F;
  // range [0, 1], 0 means linear, 1 means full exponential
  float expo = 0.35f;
  float rate_hz = 100.f;
  uint32_t timeout_ms = 200;

  float max_surge = 1.F;
  float max_sway = 1.F;
  float max_heave = 1.F;
  float max_yaw = 1.F;
  float max_pitch = 1.F;
  float max_roll = 1.F;
};

class Controller
{
private:
  struct Impl;
  Impl *impl_ = nullptr;

public:
  explicit Controller(const ControllerConfig &config = {});
  ~Controller();

  Controller(const Controller &) = delete;
  Controller &operator=(const Controller &) = delete;
  Controller(Controller &&) noexcept;
  Controller &operator=(Controller &&) noexcept;

  bool init();
  void tick();
  [[nodiscard]] const ROVCommand &command() const;
};
#endif
