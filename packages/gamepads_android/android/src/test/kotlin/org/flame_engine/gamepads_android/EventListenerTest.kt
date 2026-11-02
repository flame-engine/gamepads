package org.flame_engine.gamepads_android

import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.plugin.common.MethodChannel
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.Mockito.*

class EventListenerTest {
    private fun withDevice(keyboardType: Int, block: (EventListener, MethodChannel) -> Unit) {
        val device = mock(InputDevice::class.java)
        `when`(device.keyboardType).thenReturn(keyboardType)
        mockStatic(InputDevice::class.java).use { devices ->
            devices.`when`<InputDevice> { InputDevice.getDevice(42) }.thenReturn(device)
            mockStatic(KeyEvent::class.java).use {
                mockStatic(MotionEvent::class.java).use {
                    block(EventListener(), mock(MethodChannel::class.java))
                }
            }
        }
    }

    private fun key(code: Int, source: Int, action: Int = KeyEvent.ACTION_DOWN): KeyEvent {
        val event = mock(KeyEvent::class.java)
        `when`(event.deviceId).thenReturn(42)
        `when`(event.keyCode).thenReturn(code)
        `when`(event.source).thenReturn(source)
        `when`(event.action).thenReturn(action)
        `when`(KeyEvent.keyCodeToString(code)).thenReturn("key-$code")
        return event
    }

    private fun motion(source: Int): MotionEvent {
        val event = mock(MotionEvent::class.java)
        `when`(event.deviceId).thenReturn(42)
        `when`(event.source).thenReturn(source)
        `when`(event.getAxisValue(MotionEvent.AXIS_X)).thenReturn(0.5f)
        return event
    }

    @Test fun compositeControllerPassesTypingAndKeyboardArrowsWithoutChannelEvents() {
        withDevice(InputDevice.KEYBOARD_TYPE_ALPHABETIC) { listener, channel ->
            for (code in listOf(KeyEvent.KEYCODE_A, KeyEvent.KEYCODE_1, KeyEvent.KEYCODE_DEL,
                KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_DPAD_UP,
                KeyEvent.KEYCODE_MEDIA_RECORD)) {
                for (action in listOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
                    assertFalse(listener.onKeyEvent(key(code, InputDevice.SOURCE_KEYBOARD, action), channel))
                }
            }
            // A gamepad source must not cause ordinary typing keys to be consumed.
            assertFalse(listener.onKeyEvent(key(KeyEvent.KEYCODE_A, InputDevice.SOURCE_GAMEPAD), channel))
            verifyNoInteractions(channel)
        }
    }

    @Test fun compositeControllerForwardsGamepadButtonsIncludingKeyboardSource() {
        withDevice(InputDevice.KEYBOARD_TYPE_ALPHABETIC) { listener, channel ->
            for (action in listOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
                assertTrue(listener.onKeyEvent(key(KeyEvent.KEYCODE_BUTTON_A, InputDevice.SOURCE_KEYBOARD, action), channel))
            }
            assertTrue(listener.onKeyEvent(key(KeyEvent.KEYCODE_BUTTON_1, InputDevice.SOURCE_GAMEPAD), channel))
            assertTrue(listener.onKeyEvent(key(KeyEvent.KEYCODE_DPAD_LEFT, InputDevice.SOURCE_DPAD), channel))
            assertTrue(listener.onKeyEvent(key(KeyEvent.KEYCODE_MEDIA_RECORD, InputDevice.SOURCE_GAMEPAD), channel))
            verify(channel, times(5)).invokeMethod(eq("onGamepadEvent"), anyMap<String, Any>())
        }
    }

    @Test fun compositeMouseAndTouchPassThroughButJoystickStillForwards() {
        withDevice(InputDevice.KEYBOARD_TYPE_ALPHABETIC) { listener, channel ->
            assertFalse(listener.onMotionEvent(motion(InputDevice.SOURCE_MOUSE), channel))
            assertFalse(listener.onMotionEvent(motion(InputDevice.SOURCE_TOUCHSCREEN), channel))
            verifyNoInteractions(channel)
            assertTrue(listener.onMotionEvent(motion(InputDevice.SOURCE_JOYSTICK), channel))
            verify(channel, atLeastOnce()).invokeMethod(eq("onGamepadEvent"), anyMap<String, Any>())
        }
    }

    @Test fun ordinaryControllerKeepsLegacyKeyAndMotionRouting() {
        withDevice(InputDevice.KEYBOARD_TYPE_NONE) { listener, channel ->
            // Preserve legacy nonstandard keys and sources on non-alphabetic controllers.
            assertTrue(listener.onKeyEvent(key(KeyEvent.KEYCODE_A, InputDevice.SOURCE_KEYBOARD), channel))
            assertTrue(listener.onKeyEvent(key(KeyEvent.KEYCODE_DPAD_UP, InputDevice.SOURCE_KEYBOARD), channel))
            assertTrue(listener.onMotionEvent(motion(InputDevice.SOURCE_MOUSE), channel))
            verify(channel, atLeastOnce()).invokeMethod(eq("onGamepadEvent"), anyMap<String, Any>())
        }
    }
}
