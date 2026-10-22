#include <fcntl.h>
#include <linux/joystick.h>
#include <poll.h>
#include <unistd.h>
#include <cerrno>
#include <cstdio>

#include <cstring>
#include <fstream>
#include <functional>
#include <iostream>
#include <string>

#include "gamepad.h"
#include "utils.h"

using namespace gamepad;

constexpr int poll_timeout_ms = 500;

static int read_sysfs_hex(const std::string& path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    return 0;
  }
  int value = 0;
  file >> std::hex >> value;
  return value;
}

static std::string extract_js_name(const std::string& device_id) {
  // Extract "js0" from "/dev/input/js0"
  auto pos = device_id.rfind('/');
  if (pos == std::string::npos) {
    return device_id;
  }
  return device_id.substr(pos + 1);
}

namespace gamepad {
std::shared_ptr<GamepadInfo> get_gamepad_info(const std::string& device_id) {
  std::cout << "Opening gamepad " << device_id << std::endl;

  int file_descriptor = open(device_id.c_str(), O_RDONLY);
  if (file_descriptor == -1) {
    std::cerr << "Could not open joystick: " << strerror(errno) << std::endl;
    return nullptr;
  }

  char name[128];
  if (ioctl(file_descriptor, JSIOCGNAME(sizeof(name)), name) < 0) {
    std::cerr << "Failed to get joystick name: " << strerror(errno)
              << std::endl;
    strcpy(name, "Unknown");
  }

  std::string js_name = extract_js_name(device_id);
  std::string sysfs_base = "/sys/class/input/" + js_name + "/device/id/";
  int vendor_id = read_sysfs_hex(sysfs_base + "vendor");
  int product_id = read_sysfs_hex(sysfs_base + "product");

  auto info = std::make_shared<GamepadInfo>();
  info->device_id = device_id;
  info->name = name;
  info->file_descriptor = file_descriptor;
  info->alive = true;
  info->vendor_id = vendor_id;
  info->product_id = product_id;
  return info;
}

void listen(std::shared_ptr<GamepadInfo> gamepad,
            const std::function<void(const js_event&)>& event_consumer) {
  std::cout << "Listening to gamepad " << gamepad->device_id << std::endl;

  while (gamepad->alive) {
    struct pollfd poll_fd = {gamepad->file_descriptor, POLLIN, 0};
    int ready = poll(&poll_fd, 1, poll_timeout_ms);
    if (ready == 0 || (ready == -1 && errno == EINTR)) {
      continue;
    }
    if (ready == -1) {
      break;
    }

    struct js_event event;
    ssize_t bytes = read(gamepad->file_descriptor, &event, sizeof(event));
    if (bytes == -1 && errno == EINTR) {
      continue;
    }
    if (bytes != sizeof(event)) {
      break;
    }
    event_consumer(event);
  }

  std::cout << "Stopped listening for events: " << gamepad->device_id
            << std::endl;
  close(gamepad->file_descriptor);
}
}  // namespace gamepad