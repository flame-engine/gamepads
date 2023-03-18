#include <iostream>
#include <string>
#include <optional>
#include <unistd.h>
#include <functional>
#include <sys/inotify.h>

#include "utils.h"

namespace gamepad_connection_listener {
    enum class ConnectionEventType {
        CONNECTED,
        DISCONNECTED,
    };
    
    struct ConnectionEvent {
        ConnectionEventType type;
        std::string device;
    };

    void listen(
        bool* keep_reading,
        std::function<void(const ConnectionEvent&)> event_consumer
    );
}