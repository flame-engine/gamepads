#include <sys/inotify.h>
#include <unistd.h>
#include <atomic>
#include <functional>
#include <iostream>
#include <optional>
#include <string>

#include "utils.h"

namespace connection_listener {
enum class ConnectionEventType {
  CONNECTED,
  DISCONNECTED,
};

struct ConnectionEvent {
  ConnectionEventType type;
  std::string device_id;
};

void listen(const std::atomic<bool>* keep_reading,
            const std::function<void(const ConnectionEvent&)>& event_consumer);
}  // namespace connection_listener