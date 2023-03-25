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
 * Reads a joystick event from the joystick device.
 *
 * Returns 0 on success. Otherwise -1 is returned.
 */
int _read_event(int fd, struct js_event *event) {
    ssize_t bytes;

    bytes = read(fd, event, sizeof(*event));

    if (bytes == sizeof(*event)) {
        return 0;
    }

    /* Error, could not read full event. */
    return -1;
}

/**
 * Current state of an axis.
 */
struct _axis_state {
    short x, y;
};

/**
 * Keeps track of the current axis state.
 *
 * NOTE: This function assumes that axes are numbered starting from 0, and that
 * the X axis is an even number, and the Y axis is an odd number. However, this
 * is usually a safe assumption.
 *
 * Returns the axis that the event indicated.
 */
size_t _get_axis_state(struct js_event *event, struct _axis_state axes[3]) {
    size_t axis = event->number / 2;

    if (axis < 3) {
        if (event->number % 2 == 0) {
            axes[axis].x = event->value;
        } else {
            axes[axis].y = event->value;
        }
    }

    return axis;
}

std::optional<std::string> _parse_event_string(js_event event, struct _axis_state axes[3]) {
    switch (event.type) {
        case JS_EVENT_BUTTON: {
            return string_format("Button %u %s\n", event.number, event.value ? "pressed" : "released");
        }
        case JS_EVENT_AXIS: {
            size_t axis = _get_axis_state(&event, axes);
            if (axis < 3) {
                return string_format("Axis %zu at (%6d, %6d)\n", axis, axes[axis].x, axes[axis].y);
            } else {
                return string_format("Unknown event %d", axis);
            }
        }
        default:
            /* Ignore init events. */
            return std::nullopt;
    } 
}

namespace gamepad_listener {
    void listen(
        const std::string& device,
        bool* keep_reading,
        const std::function<void(const GamepadEvent&)>& event_consumer
    ) {
        std::cout << "Listening to gamepad " << device << std::endl;

        int js = open(device.c_str(), O_RDONLY);
        if (js == -1) {
            std::cerr << "Could not open joystick: " << js << std::endl;
            *keep_reading = false;
            return;
        }

        struct _axis_state axes[3] = {{0}};
        while (*keep_reading) {
            struct js_event event;
            _read_event(js, &event);
            std::optional<std::string> value = _parse_event_string(event, axes);
            if (value) {
                GamepadEvent gamepadEvent = {device, *value};
                event_consumer(gamepadEvent);
            }
        }

        std::cout << "Stopped listening for events: " << device << std::endl;
        close(js);
    }
}