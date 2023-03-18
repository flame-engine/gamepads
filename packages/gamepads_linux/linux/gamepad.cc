#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <linux/joystick.h>

#include <iostream>
#include <string>
#include <functional>
#include <optional>

#include "format.h"

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
 * Returns the number of axes on the controller or 0 if an error occurs.
 */
size_t _get_axis_count(int fd) {
    __u8 axes;

    if (ioctl(fd, JSIOCGAXES, &axes) == -1) {
        return 0;
    }

    return axes;
}

/**
 * Returns the number of buttons on the controller or 0 if an error occurs.
 */
size_t _get_button_count(int fd) {
    __u8 buttons;
    if (ioctl(fd, JSIOCGBUTTONS, &buttons) == -1) {
        return 0;
    }

    return buttons;
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

std::optional<std::string> _parse_event(js_event event, struct _axis_state axes[3]) {
    switch (event.type) {
        case JS_EVENT_BUTTON: {
            return string_format("Button %u %s\n", event.number, event.value ? "pressed" : "released");
            break;
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

namespace gamepad {
    void game_event_read_loop(
        std::string device,
        bool *keep_reading,
        std::function<void(const std::string&)> consume_event
    ) {
        int js = open(device.c_str(), O_RDONLY);
        if (js == -1) {
            std::cerr << "Could not open joystick: " << js << std::endl;
        }

        struct _axis_state axes[3] = {{0}};
        while (*keep_reading) {
            struct js_event event;
            _read_event(js, &event);
            std::optional<std::string> value = _parse_event(event, axes);
            if (value) {
                consume_event(*value);
            }
        }

        close(js);
    }
}