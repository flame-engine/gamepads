#include <fcntl.h>
#include <linux/joystick.h>
#include <unistd.h>

#include <atomic>
#include <functional>
#include <memory>
#include <string>

#include "utils.h"

namespace gamepad {
struct GamepadInfo {
  std::string device_id;
  std::string name;
  int file_descriptor;
  std::atomic<bool> alive;
  int vendor_id;
  int product_id;
};

std::shared_ptr<GamepadInfo> get_gamepad_info(const std::string& device);

void listen(std::shared_ptr<GamepadInfo> gamepad,
            const std::function<void(const js_event&)>& event_consumer);
}  // namespace gamepad
