package dev.markvideon.gamepads_android

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

interface GamepadsCompatibleActivity {
    fun isGamepadsInputDevice(device: InputDevice): Boolean
    fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?)
    fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean)
    fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean)
}