#include <fcntl.h>
#include <linux/joystick.h>
#include <unistd.h>
#include <cstdio>

#include <cstring>
#include <fstream>
#include <functional>
#include <iostream>
#include <string>

#include "gamepad.h"
#include "utils.h"

using namespace gamepad;

/**
 * Reads a joystick event from the joystick gamepad_id.
 *
 * Returns 0 on success. Otherwise -1 is returned.
 */
static int read_event(int fd, struct js_event* event) {
  ssize_t bytes;

  bytes = read(fd, event, sizeof(*event));

  if (bytes == sizeof(*event)) {
    return 0;
  }

  /* Error, could not read full event. */
  return -1;
}

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
std::optional<GamepadInfo> get_gamepad_info(const std::string& device_id) {
  std::cout << "Listening to gamepad " << device_id << std::endl;

  int file_descriptor = open(device_id.c_str(), O_RDONLY);
  if (file_descriptor == -1) {
    std::cerr << "Could not open joystick: " << file_descriptor << std::endl;
    return std::nullopt;
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

  return {{device_id, name, file_descriptor, true, vendor_id, product_id}};
}

void listen(GamepadInfo* gamepad,
            const std::function<void(const js_event&)>& event_consumer) {
  std::cout << "Listening to gamepad " << gamepad->device_id << std::endl;

  while (gamepad->alive) {
    struct js_event event;
    read_event(gamepad->file_descriptor, &event);
    event_consumer(event);
  }

  std::cout << "Stopped listening for events: " << gamepad->device_id
            << std::endl;
  close(gamepad->file_descriptor);
}
}  // namespace gamepad