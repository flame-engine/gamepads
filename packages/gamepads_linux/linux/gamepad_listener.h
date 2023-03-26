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

namespace gamepad_listener {
    void listen(
        const std::string& device,
        bool* keep_reading,
        const std::function<void(const js_event&)>& event_consumer
    );
}