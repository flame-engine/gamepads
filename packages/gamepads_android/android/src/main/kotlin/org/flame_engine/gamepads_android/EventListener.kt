package org.flame_engine.gamepads_android

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
    }
    private val lastAxisValue = mutableMapOf<Int, Float>()
    // Reference: https://developer.android.com/reference/android/view/MotionEvent
    private val supportedAxes = listOf(
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
    )

    fun onKeyEvent(keyEvent: KeyEvent, channel: MethodChannel): Boolean {
        val arguments = mapOf(
            "gamepadId" to keyEvent.deviceId.toString(),
            "time" to keyEvent.eventTime,
            "type" to "button",
            "key" to KeyEvent.keyCodeToString(keyEvent.keyCode),
            "value" to keyEvent.action.toDouble()
        )
        channel.invokeMethod("onGamepadEvent", arguments)
        return true
    }

    fun onMotionEvent(motionEvent: MotionEvent, channel: MethodChannel): Boolean {
        supportedAxes.forEach {
            reportAxis(motionEvent, channel, it)
        }
        return true
    }

    private fun reportAxis(
        motionEvent: MotionEvent,
        channel: MethodChannel,
        axis: SupportedAxis,
    ): Boolean {
        val multiplier = if (axis.invert) -1 else 1
        val value = motionEvent.getAxisValue(axis.axisId) * multiplier

        // No-op if threshold is not met
        val lastValue = lastAxisValue[axis.axisId]
        if (lastValue is Float) {
            if (abs(value - lastValue) < EPSILON) {
                return true
            }
        }
        // Update last value
        lastAxisValue[axis.axisId] = value

        val arguments = mapOf(
            "gamepadId" to motionEvent.deviceId.toString(),
            "time" to motionEvent.eventTime,
            "type" to "analog",
            "key" to MotionEvent.axisToString(axis.axisId),
            "value" to value,
        )
        channel.invokeMethod("onGamepadEvent", arguments)
        return true
    }
}