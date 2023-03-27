/**
 * This file was inspired by Jason White's work here:
 * https://gist.github.com/jasonwhite/c5b2048c15993d285130
 *
 * See also:
 * https://www.kernel.org/doc/Documentation/input/joystick-api.txt
 */

#include <fcntl.h>
#include <unistd.h>
#include <linux/joystick.h>

#include <string>
#include <functional>
#include <optional>

#include "utils.h"

namespace gamepad {
    struct GamepadInfo {
        std::string device_id;
        std::string name;
        int file_descriptor;
        bool alive;
    };

    std::optional<GamepadInfo> get_gamepad_info(
        const std::string& device
    );

    void listen(
        GamepadInfo* gamepad,
        const std::function<void(const js_event&)>& event_consumer
    );
}