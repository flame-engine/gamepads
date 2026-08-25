package org.flame_engine.gamepads_android

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

interface GamepadsCompatibleActivity {
    fun isGamepadsInputDevice(device: InputDevice): Boolean {
        val hasGamepadSource =
            device.sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD ||
                device.sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
        if (!hasGamepadSource) {
            return false
        }
        // Some bluetooth keyboards claim a gamepad source, while some real
        // controllers expose an alphabetic keyboard profile, so keyboard type
        // alone cannot tell them apart. Real controllers report joystick axes
        // (sticks, hats or triggers) and keyboards do not.
        val hasJoystickAxes = device.motionRanges.any {
            it.source and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
        }
        val isKeyboard =
            device.keyboardType == InputDevice.KEYBOARD_TYPE_ALPHABETIC && !hasJoystickAxes
        return !isKeyboard
    }

    fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?)
    fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean)
    fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean)
}