package org.flame_engine.gamepads_android

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

class GamepadsCompatibleActivityTest {
    private val activity = object : GamepadsCompatibleActivity {
        override fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?) {}
        override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {}
        override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {}
    }

    private fun device(
        name: String = "Wireless Controller",
        sources: Int = InputDevice.SOURCE_GAMEPAD or InputDevice.SOURCE_JOYSTICK,
        keyboardType: Int = InputDevice.KEYBOARD_TYPE_NONE,
        axisSource: Int? = InputDevice.SOURCE_JOYSTICK,
        axis: Int = MotionEvent.AXIS_X,
        buttons: Set<Int> = emptySet(),
    ): InputDevice {
        val device = mock(InputDevice::class.java)
        `when`(device.name).thenReturn(name)
        `when`(device.sources).thenReturn(sources)
        `when`(device.keyboardType).thenReturn(keyboardType)
        val ranges = if (axisSource == null) emptyList() else {
            val range = mock(InputDevice.MotionRange::class.java)
            `when`(range.source).thenReturn(axisSource)
            `when`(range.axis).thenReturn(axis)
            listOf(range)
        }
        `when`(device.motionRanges).thenReturn(ranges)
        val buttonCodes = ((KeyEvent.KEYCODE_BUTTON_A..KeyEvent.KEYCODE_BUTTON_MODE) +
            (KeyEvent.KEYCODE_BUTTON_1..KeyEvent.KEYCODE_BUTTON_16)).toIntArray()
        `when`(device.hasKeys(*buttonCodes)).thenReturn(
            BooleanArray(buttonCodes.size) { buttonCodes[it] in buttons }
        )
        return device
    }

    @Test fun compositeControllerWithStandardJoystickAxisIsAccepted() {
        for (sources in listOf(InputDevice.SOURCE_JOYSTICK,
            InputDevice.SOURCE_GAMEPAD or InputDevice.SOURCE_JOYSTICK)) {
            assertTrue(activity.isGamepadsInputDevice(device(
                sources = sources,
                keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
            )))
        }
    }

    @Test fun compositeButtonOnlyControllerIsAccepted() {
        assertTrue(activity.isGamepadsInputDevice(device(
            sources = InputDevice.SOURCE_GAMEPAD or InputDevice.SOURCE_KEYBOARD,
            keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
            axisSource = null,
            buttons = setOf(KeyEvent.KEYCODE_BUTTON_A),
        )))
    }

    @Test fun compositeControllerWithGenericAxisAndGamepadButtonIsAccepted() {
        assertTrue(activity.isGamepadsInputDevice(device(
            keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
            axis = MotionEvent.AXIS_GENERIC_1,
            buttons = setOf(KeyEvent.KEYCODE_BUTTON_1),
        )))
    }

    @Test fun keyboardDirectionAndMediaKeysDoNotQualifyAsGamepadControls() {
        assertFalse(activity.isGamepadsInputDevice(device(
            keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
            axis = MotionEvent.AXIS_GENERIC_1,
            buttons = setOf(KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_MEDIA_RECORD),
        )))
    }

    @Test fun nonAlphabeticGamepadWithOnlyGenericAxisKeepsOriginalAcceptance() {
        assertTrue(activity.isGamepadsInputDevice(device(axis = MotionEvent.AXIS_GENERIC_1)))
    }

    @Test fun vxeCompositeKeyboardWithGenericJoystickAxisIsRejected() {
        assertFalse(activity.isGamepadsInputDevice(device(
            name = "VXE V87 BT2 Keyboard",
            sources = InputDevice.SOURCE_KEYBOARD or InputDevice.SOURCE_DPAD or
                InputDevice.SOURCE_MOUSE_RELATIVE or InputDevice.SOURCE_JOYSTICK,
            keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
            axis = MotionEvent.AXIS_GENERIC_1,
        )))
    }

    @Test fun ordinaryJoystickIsStillAccepted() {
        assertTrue(activity.isGamepadsInputDevice(device()))
    }

    @Test fun alphabeticKeyboardClaimingGamepadSourceIsRejectedWithoutJoystickAxes() {
        for (axisSource in listOf(null, InputDevice.SOURCE_MOUSE)) {
            assertFalse(activity.isGamepadsInputDevice(device(
                name = "Bluetooth Keyboard",
                keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
                axisSource = axisSource,
            )))
        }
    }

    @Test fun keyboardWithoutGamepadSourceIsRejected() {
        assertFalse(activity.isGamepadsInputDevice(device(
            sources = InputDevice.SOURCE_KEYBOARD,
            keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
            axisSource = null,
        )))
    }

    @Test fun buttonOnlyGamepadIsStillAccepted() {
        assertTrue(activity.isGamepadsInputDevice(device(
            sources = InputDevice.SOURCE_GAMEPAD,
            axisSource = null,
        )))
    }

    @Test fun compositeControllerWithRxRyAxesIsAccepted() {
        for (axis in listOf(MotionEvent.AXIS_RX, MotionEvent.AXIS_RY)) {
            assertTrue(activity.isGamepadsInputDevice(device(
                keyboardType = InputDevice.KEYBOARD_TYPE_ALPHABETIC,
                axis = axis,
            )))
        }
    }
}
