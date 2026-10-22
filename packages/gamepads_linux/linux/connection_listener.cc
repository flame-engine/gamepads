#include <poll.h>
#include <unistd.h>
#include <cerrno>
#include <cstring>
#include <functional>
#include <iostream>
#include <optional>
#include <string>

#include <dirent.h>
#include <sys/inotify.h>
#include <map>

#include "connection_listener.h"
#include "utils.h"

using namespace connection_listener;

const std::string _input_dir = "/dev/input/";
constexpr int _poll_timeout_ms = 500;

std::map<ConnectionEventType, const char*> connectionEventTypeNames = {
    {ConnectionEventType::CONNECTED, "CONNECTED"},
    {ConnectionEventType::DISCONNECTED, "DISCONNECTED"},
};

std::optional<ConnectionEventType> _parseEventType(inotify_event* event) {
  uint mask = event->mask;
  if ((mask & IN_CREATE) || (mask & IN_ATTRIB)) {
    return ConnectionEventType::CONNECTED;
  } else if (mask & IN_DELETE) {
    return ConnectionEventType::DISCONNECTED;
  } else {
    return std::nullopt;
  }
}

void _list_existing(
    const std::function<void(const ConnectionEvent&)>& event_consumer) {
  DIR* dir = opendir(_input_dir.c_str());

  if (!dir) {
    std::cerr << "Error reading existing connections: failed to open "
              << _input_dir << ": " << strerror(errno) << std::endl;
    return;
  }

  struct dirent* entry;
  std::vector<std::string> devices;
  while ((entry = readdir(dir)) != nullptr) {
    if (entry->d_type != DT_CHR) {
      continue;
    }
    if (!starts_with(entry->d_name, "js")) {
      continue;
    }
    std::string device = _input_dir + entry->d_name;
    devices.push_back(device);
  }

  closedir(dir);

  for (std::string& device : devices) {
    ConnectionEvent connectionEvent = {ConnectionEventType::CONNECTED, device};
    event_consumer(connectionEvent);
  }
}

/// Returns false when inotify can no longer be read.
bool _wait_for_connections(
    int inotify,
    const std::function<void(const ConnectionEvent&)>& event_consumer) {
  struct pollfd poll_fd = {inotify, POLLIN, 0};
  int ready = poll(&poll_fd, 1, _poll_timeout_ms);
  if (ready == 0 || (ready == -1 && errno == EINTR)) {
    return true;
  }
  if (ready == -1) {
    std::cerr << "Error polling inotify events: " << strerror(errno)
              << std::endl;
    return false;
  }

  char buffer[4096] __attribute__((aligned(__alignof__(struct inotify_event))));
  ssize_t len = read(inotify, buffer, sizeof(buffer));
  if (len < 0) {
    if (errno == EINTR) {
      return true;
    }
    std::cerr << "Error reading inotify events: " << strerror(errno)
              << std::endl;
    return false;
  }

  char* ptr = buffer;
  while (ptr < buffer + len) {
    auto* event = reinterpret_cast<struct inotify_event*>(ptr);
    ptr += sizeof(struct inotify_event) + event->len;

    std::string name = event->len > 0 ? event->name : "";
    if (!starts_with(name, "js")) {
      continue;
    }
    std::optional<ConnectionEventType> type = _parseEventType(event);
    if (!type) {
      continue;
    }

    std::string device = _input_dir + name;
    std::cout << "Connection found: " << connectionEventTypeNames[*type]
              << " - " << name << std::endl;
    ConnectionEvent connection_event = {*type, device};
    event_consumer(connection_event);
  }
  return true;
}

namespace connection_listener {
void listen(const std::atomic<bool>* keep_reading,
            const std::function<void(const ConnectionEvent&)>& event_consumer) {
  std::cout << "Reading initial gamepads..." << std::endl;
  _list_existing(event_consumer);

  int inotify = inotify_init();
  if (inotify == -1) {
    std::cerr << "Error initializing inotify: " << strerror(errno) << std::endl;
    return;
  }
  int watcher = inotify_add_watch(inotify, _input_dir.c_str(),
                                  IN_CREATE | IN_DELETE | IN_ATTRIB);
  if (watcher == -1) {
    int error = errno;
    std::cerr << "Error adding watch for " << _input_dir << ": "
              << strerror(error);
    if (error == ENOSPC) {
      std::cerr << " (see fs.inotify.max_user_watches)";
    }
    std::cerr << std::endl;
    close(inotify);
    return;
  }

  std::cout << "Listening for gamepads..." << std::endl;
  while (*keep_reading) {
    if (!_wait_for_connections(inotify, event_consumer)) {
      break;
    }
  }
  std::cout << "Stopped listening for gamepads." << std::endl;

  // Remove the inotify watch and close the file descriptor
  inotify_rm_watch(inotify, watcher);
  close(inotify);
}
}  // namespace connection_listener