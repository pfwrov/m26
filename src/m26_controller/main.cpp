#include <fmt/base.h>
#include <fmt/format.h>
#include <thread>

#include <m26/m26_controller.hpp>

#include <internal_use_only/config.hpp>

int main()
{

  Controller ctr;
  if (!ctr.init()) {
    fmt::print("Controller init failed\n");
    return 1;
  }


  using namespace std::chrono_literals;
  while (true) {
    ctr.tick();
    auto cmd = ctr.command();
    fmt::print(
      "\rarmed={} killed={} surge={:+.2f} sway={:+.2f} heave={:+.2f} yaw={:+.2f} pitch={:+.2f} roll={:+.2f}      ",
      cmd.armed,
      cmd.killed,
      cmd.surge,
      cmd.sway,
      cmd.heave,
      cmd.yaw,
      cmd.pitch,
      cmd.roll);
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }
}
