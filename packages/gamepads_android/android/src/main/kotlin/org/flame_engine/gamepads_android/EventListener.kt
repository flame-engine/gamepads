package org.flame_engine.gamepads_android

import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

data class SupportedAxis(
    val axisId: Int,
    val invert: Boolean = false,
)

class EventListener {
    companion object {
        private const val EPSILON = 0.001
        private val LEFT_TRIGGER_AXES = setOf(MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_BRAKE)
        private val RIGHT_TRIGGER_AXES = setOf(
            MotionEvent.AXIS_RTRIGGER, MotionEvent.AXIS_GAS, MotionEvent.AXIS_THROTTLE,
        )
        // Shared with composite device detection so accepted axes are supported.
        // Reference: https://developer.android.com/reference/android/view/MotionEvent
        //
        // The vertical axes are inverted here so that the values sent to Dart
        // follow up = +1.0, down = -1.0 instead of Android's native convention.
        // AndroidMapping in the gamepads package relies on that and does not
        // invert them again, so removing an `invert` below silently flips the
        // corresponding stick or d-pad direction. See issue #123.
        internal val supportedAxes = listOf(
            SupportedAxis(MotionEvent.AXIS_X),
            SupportedAxis(MotionEvent.AXIS_Y, invert = true),
            SupportedAxis(MotionEvent.AXIS_Z),
            SupportedAxis(MotionEvent.AXIS_RZ, invert = true),
            SupportedAxis(MotionEvent.AXIS_HAT_X),
            SupportedAxis(MotionEvent.AXIS_HAT_Y, invert = true),
            SupportedAxis(MotionEvent.AXIS_LTRIGGER),
            SupportedAxis(MotionEvent.AXIS_RTRIGGER),
            SupportedAxis(MotionEvent.AXIS_BRAKE),
            SupportedAxis(MotionEvent.AXIS_GAS),
            SupportedAxis(MotionEvent.AXIS_THROTTLE),
            SupportedAxis(MotionEvent.AXIS_WHEEL),
            // Right-stick axes for non-Xbox layouts (Xbox uses AXIS_Z/RZ).
            // E.g. DJI RC Pro reports its right stick on RX/RY.
            SupportedAxis(MotionEvent.AXIS_RX),
            SupportedAxis(MotionEvent.AXIS_RY, invert = true),
        )
    }
    private val lastAxisValue = mutableMapOf<Pair<Int, Int>, Float>()

    private fun isCompositeGamepadKey(event: KeyEvent): Boolean {
        // Some controllers report gamepad buttons with a KEYBOARD source.
        if (event.keyCode in gamepadButtonKeyCodes) return true
        val hasControllerSource =
            event.source and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD ||
            event.source and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK ||
            event.source and InputDevice.SOURCE_DPAD == InputDevice.SOURCE_DPAD
        if (!hasControllerSource) return false
        return when (event.keyCode) {
            KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_DPAD_RIGHT,
            KeyEvent.KEYCODE_MEDIA_RECORD -> true
            else -> false
        }
    }

    fun onKeyEvent(keyEvent: KeyEvent, channel: MethodChannel): Boolean {
        val device = InputDevice.getDevice(keyEvent.deviceId)
        // Let the Activity handle typing keys from an accepted composite device.
        // Do not change legacy routing for non-alphabetic controllers.
        if (device?.keyboardType == InputDevice.KEYBOARD_TYPE_ALPHABETIC &&
            !isCompositeGamepadKey(keyEvent)) return false
        val arguments = mutableMapOf<String, Any>(
            "gamepadId" to keyEvent.deviceId.toString(),
            "time" to keyEvent.eventTime,
            "type" to "button",
            "key" to KeyEvent.keyCodeToString(keyEvent.keyCode),
            "value" to if (keyEvent.action == KeyEvent.ACTION_DOWN) 1.0 else 0.0,
        )
        if (device != null) {
            arguments["vendorId"] = device.vendorId
            arguments["productId"] = device.productId
        }
        channel.invokeMethod("onGamepadEvent", arguments)
        return true
    }

    fun onMotionEvent(motionEvent: MotionEvent, channel: MethodChannel): Boolean {
        val device = InputDevice.getDevice(motionEvent.deviceId)
        if (device?.keyboardType == InputDevice.KEYBOARD_TYPE_ALPHABETIC &&
            motionEvent.source and InputDevice.SOURCE_JOYSTICK != InputDevice.SOURCE_JOYSTICK) {
            return false
        }
        var handled = false
        // Match Chromium's generic mapping: use only advertised joystick ranges,
        // with the last supported alias winning for each trigger. Reporting absent
        // axes as zero would overwrite a real trigger or disable digital fallback.
        val ranges = device?.motionRanges.orEmpty()
            .filter { (it.source and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK }
        val leftTrigger = ranges.lastOrNull { it.axis in LEFT_TRIGGER_AXES }?.axis
        val rightTrigger = ranges.lastOrNull { it.axis in RIGHT_TRIGGER_AXES }?.axis
        supportedAxes.forEach { axis ->
            if (axis.axisId in LEFT_TRIGGER_AXES && axis.axisId != leftTrigger) return@forEach
            if (axis.axisId in RIGHT_TRIGGER_AXES && axis.axisId != rightTrigger) return@forEach
            val axisHandled = reportAxis(motionEvent, channel, axis)
            if (axisHandled) handled = true
        }

        return handled
    }

    private fun reportAxis(
        motionEvent: MotionEvent,
        channel: MethodChannel,
        axis: SupportedAxis,
    ): Boolean {
        val multiplier = if (axis.invert) -1 else 1
        val value = motionEvent.getAxisValue(axis.axisId) * multiplier

        // No-op if threshold is not met
        // A second controller must emit its own initial trigger state, even if
        // the first controller last reported the same value.
        val axisKey = motionEvent.deviceId to axis.axisId
        val lastValue = lastAxisValue[axisKey]
        if (lastValue is Float) {
            if (abs(value - lastValue) < EPSILON) {
                return true
            }
        }
        // Update last value
        lastAxisValue[axisKey] = value

        val device = InputDevice.getDevice(motionEvent.deviceId)
        val arguments = mutableMapOf<String, Any>(
            "gamepadId" to motionEvent.deviceId.toString(),
            "time" to motionEvent.eventTime,
            "type" to "analog",
            "key" to MotionEvent.axisToString(axis.axisId),
            "value" to value,
        )
        if (device != null) {
            arguments["vendorId"] = device.vendorId
            arguments["productId"] = device.productId
        }
        channel.invokeMethod("onGamepadEvent", arguments)
        return true
    }
}
