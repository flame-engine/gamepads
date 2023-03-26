#include <fcntl.h>
#include <cstdio>
#include <unistd.h>
#include <linux/joystick.h>

#include <iostream>
#include <string>
#include <functional>
#include <optional>

#include "utils.h"
#include "gamepad_listener.h"

using namespace gamepad_listener;

/**
 * Reads a joystick event from the joystick gamepad_id.
 *
 * Returns 0 on success. Otherwise -1 is returned.
 */
static int read_event(int fd, struct js_event *event) {
    ssize_t bytes;

    bytes = read(fd, event, sizeof(*event));

    if (bytes == sizeof(*event)) {
        return 0;
    }

    /* Error, could not read full event. */
    return -1;
}

namespace gamepad_listener {
    void listen(
        const std::string& device,
        bool* keep_reading,
        const std::function<void(const js_event&)>& event_consumer
    ) {
        std::cout << "Listening to gamepad " << device << std::endl;

        int js = open(device.c_str(), O_RDONLY);
        if (js == -1) {
            std::cerr << "Could not open joystick: " << js << std::endl;
            *keep_reading = false;
            return;
        }

        while (*keep_reading) {
            struct js_event event;
            read_event(js, &event);
            event_consumer(event);
        }

        std::cout << "Stopped listening for events: " << device << std::endl;
        close(js);
    }
}