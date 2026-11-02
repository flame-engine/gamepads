package org.flame_engine.gamepads_android

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

// The same button ranges as KeyEvent.isGamepadButton. D-pad and media keys alone
// are not evidence of gamepad controls on a composite typing keyboard.
internal val gamepadButtonKeyCodes = ((KeyEvent.KEYCODE_BUTTON_A..KeyEvent.KEYCODE_BUTTON_MODE) +
    (KeyEvent.KEYCODE_BUTTON_1..KeyEvent.KEYCODE_BUTTON_16)).toIntArray()

interface GamepadsCompatibleActivity {
    fun isGamepadsInputDevice(device: InputDevice): Boolean {
        val hasGamepadSource =
            device.sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD ||
                device.sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
        if (!hasGamepadSource) {
            return false
        }
        // Preserve the existing path for ordinary and button-only controllers.
        if (device.keyboardType != InputDevice.KEYBOARD_TYPE_ALPHABETIC) return true

        // Composite typing keyboards can also report joystick ranges (e.g.
        // VXE V87 BT2 reports GENERIC_1). Require an axis we actually support,
        // or a gamepad button, rather than accepting any joystick range.
        val hasSupportedJoystickAxis = device.motionRanges.any { range ->
            range.source and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK &&
                EventListener.supportedAxes.any { it.axisId == range.axis }
        }
        return hasSupportedJoystickAxis || device.hasKeys(*gamepadButtonKeyCodes).any { it }
    }

    fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?)
    fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean)
    fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean)
}
