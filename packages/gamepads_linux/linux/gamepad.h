/**
 * This file was inspired by Jason White's work here:
 * https://gist.github.com/jasonwhite/c5b2048c15993d285130
 *
 * See also:
 * https://www.kernel.org/doc/Documentation/input/joystick-api.txt
 */

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <linux/joystick.h>

#include <string>
#include <functional>
#include <optional>

#include "format.h"

namespace gamepad {
    void game_event_read_loop(
        std::string device,
        bool *keep_reading,
        std::function<void(const std::string&)> consume_event
    );
}