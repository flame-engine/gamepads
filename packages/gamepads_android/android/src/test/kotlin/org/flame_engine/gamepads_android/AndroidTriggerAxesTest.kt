package org.flame_engine.gamepads_android

import android.view.InputDevice
import android.view.MotionEvent
import io.flutter.plugin.common.MethodChannel
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.ArgumentMatchers.anyMap
import org.mockito.ArgumentMatchers.eq
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.mock
import org.mockito.Mockito.mockStatic
import org.mockito.Mockito.`when`

class AndroidTriggerAxesTest {
    private val triggerAxes = setOf(
        MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER,
        MotionEvent.AXIS_BRAKE, MotionEvent.AXIS_GAS, MotionEvent.AXIS_THROTTLE,
    )

    private fun triggerEvents(
        axes: List<Int>,
        values: Map<Int, Float>,
        source: Int = InputDevice.SOURCE_JOYSTICK,
        deviceIds: List<Int> = listOf(7),
    ): List<Pair<Int, Float>> {
        val device = mock(InputDevice::class.java)
        val ranges = axes.map { axis ->
            mock(InputDevice.MotionRange::class.java).also {
                `when`(it.axis).thenReturn(axis)
                `when`(it.source).thenReturn(source)
            }
        }
        `when`(device.motionRanges).thenReturn(ranges)
        val event = mock(MotionEvent::class.java)
        `when`(event.deviceId).thenReturn(7)
        values.forEach { (axis, value) -> `when`(event.getAxisValue(axis)).thenReturn(value) }
        val channel = mock(MethodChannel::class.java)
        val result = mutableListOf<Pair<Int, Float>>()
        doAnswer { call ->
            val arguments = call.getArgument<Map<String, Any>>(1)
            val axis = (arguments["key"] as String).toInt()
            if (axis in triggerAxes) result.add(axis to arguments["value"] as Float)
            null
        }.`when`(channel).invokeMethod(eq("onGamepadEvent"), anyMap<String, Any>())
        mockStatic(InputDevice::class.java).use { devices ->
            devices.`when`<InputDevice> { InputDevice.getDevice(anyInt()) }.thenReturn(device)
            mockStatic(MotionEvent::class.java).use { motions ->
                motions.`when`<String> { MotionEvent.axisToString(anyInt()) }
                    .thenAnswer { it.getArgument<Int>(0).toString() }
                val listener = EventListener()
                deviceIds.forEach { id ->
                    `when`(event.deviceId).thenReturn(id)
                    listener.onMotionEvent(event, channel)
                }
            }
        }
        return result
    }

    @Test fun standardTriggersDoNotEmitAbsentAliases() {
        assertEquals(
            listOf(MotionEvent.AXIS_LTRIGGER to 0.4f, MotionEvent.AXIS_RTRIGGER to 0.8f),
            triggerEvents(
                listOf(MotionEvent.AXIS_X, MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER),
                mapOf(MotionEvent.AXIS_X to 0.5f, MotionEvent.AXIS_LTRIGGER to 0.4f,
                    MotionEvent.AXIS_RTRIGGER to 0.8f),
            ),
        )
    }

    @Test fun brakeAndThrottleWorkAlongsideSticks() {
        assertEquals(
            listOf(MotionEvent.AXIS_BRAKE to 0.25f, MotionEvent.AXIS_THROTTLE to 0.75f),
            triggerEvents(
                listOf(MotionEvent.AXIS_X, MotionEvent.AXIS_Z,
                    MotionEvent.AXIS_BRAKE, MotionEvent.AXIS_THROTTLE),
                mapOf(MotionEvent.AXIS_X to 1f, MotionEvent.AXIS_Z to -1f,
                    MotionEvent.AXIS_BRAKE to 0.25f, MotionEvent.AXIS_THROTTLE to 0.75f),
            ),
        )
    }

    @Test fun lastAdvertisedAliasWinsWithoutAnotherAliasOverwritingIt() {
        assertEquals(
            listOf(MotionEvent.AXIS_LTRIGGER to 0.5f, MotionEvent.AXIS_GAS to 0.6f),
            triggerEvents(
                listOf(MotionEvent.AXIS_BRAKE, MotionEvent.AXIS_LTRIGGER,
                    MotionEvent.AXIS_RTRIGGER, MotionEvent.AXIS_THROTTLE, MotionEvent.AXIS_GAS),
                mapOf(MotionEvent.AXIS_LTRIGGER to 0.5f, MotionEvent.AXIS_GAS to 0.6f),
            ),
        )
    }

    @Test fun digitalTriggersReceiveNoInventedAnalogZeroFromStickEvents() {
        assertEquals(emptyList<Pair<Int, Float>>(), triggerEvents(
            listOf(MotionEvent.AXIS_X, MotionEvent.AXIS_Y, MotionEvent.AXIS_Z, MotionEvent.AXIS_RZ),
            mapOf(MotionEvent.AXIS_X to 1f),
        ))
    }

    @Test fun nonJoystickRangesAreNotTriggerCapabilities() {
        assertEquals(emptyList<Pair<Int, Float>>(), triggerEvents(
            listOf(MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER),
            emptyMap(), InputDevice.SOURCE_MOUSE,
        ))
    }

    @Test fun secondControllerEmitsItsOwnAnalogZeroForDigitalFallbackPriority() {
        assertEquals(listOf(MotionEvent.AXIS_LTRIGGER to 0f, MotionEvent.AXIS_LTRIGGER to 0f),
            triggerEvents(listOf(MotionEvent.AXIS_LTRIGGER), emptyMap(), deviceIds = listOf(7, 8)))
    }
}
