package org.flame_engine.gamepads_android

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

interface GamepadsCompatibleActivity {
    fun isGamepadsInputDevice(device: InputDevice): Boolean {
        return device.sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD
                || device.sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
                // Some bluetooth keyboards are identified as GamePad. Check if it is ALPHABETIC keyboard.
                && device.keyboardType != InputDevice.KEYBOARD_TYPE_ALPHABETIC
    }

    fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?)
    fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean)
    fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean)
}