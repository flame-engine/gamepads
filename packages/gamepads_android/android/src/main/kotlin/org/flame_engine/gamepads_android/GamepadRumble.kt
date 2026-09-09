package org.flame_engine.gamepads_android

import android.os.Build
import android.os.CombinedVibration
import android.os.VibrationEffect
import android.view.InputDevice
import kotlin.math.max
import kotlin.math.roundToInt

// Uses the controller's actuators, never the phone's system vibrator.
internal class GamepadRumble {
    private val active = mutableMapOf<Int, InputDevice>()

    fun has(id: String): Boolean {
        val device = device(id) ?: return false
        return if (Build.VERSION.SDK_INT >= 31) {
            device.vibratorManager.vibratorIds.isNotEmpty()
        } else {
            @Suppress("DEPRECATION")
            device.vibrator.hasVibrator()
        }
    }

    fun set(id: String, low: Double, high: Double, duration: Int): Boolean {
        if (!low.isFinite() || !high.isFinite() || low !in 0.0..1.0 ||
            high !in 0.0..1.0 || duration !in 0..30000) return false
        if (duration == 0 || (low == 0.0 && high == 0.0)) return stop(id)
        val device = device(id) ?: return false
        try {
            if (!has(id)) return false
            if (Build.VERSION.SDK_INT >= 31) {
                val manager = device.vibratorManager
                val ids = manager.vibratorIds
                manager.cancel()
                val combined = CombinedVibration.startParallel()
                for ((index, vibratorId) in ids.withIndex()) {
                    val strength = if (ids.size == 2) {
                        if (index == 0) low else high
                    } else max(low, high)
                    if (strength > 0) {
                        combined.addVibrator(vibratorId, VibrationEffect.createOneShot(
                            duration.toLong(), (strength * 255).roundToInt().coerceIn(1, 255)))
                    }
                }
                manager.vibrate(combined.combine())
            } else {
                @Suppress("DEPRECATION")
                val vibrator = device.vibrator
                vibrator.cancel()
                if (Build.VERSION.SDK_INT >= 26) {
                    vibrator.vibrate(VibrationEffect.createOneShot(duration.toLong(),
                        (max(low, high) * 255).roundToInt().coerceIn(1, 255)))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(duration.toLong())
                }
            }
            active[device.id] = device
            return true
        } catch (_: RuntimeException) {
            return false
        }
    }

    fun stop(id: String): Boolean {
        val number = id.toIntOrNull() ?: return false
        val device = active.remove(number) ?: device(id) ?: return false
        return cancel(device)
    }

    fun stopAll() {
        active.values.forEach { cancel(it) }
        active.clear()
    }

    private fun cancel(device: InputDevice): Boolean = try {
        if (Build.VERSION.SDK_INT >= 31) device.vibratorManager.cancel()
        else {
            @Suppress("DEPRECATION")
            device.vibrator.cancel()
        }
        true
    } catch (_: RuntimeException) { false }

    private fun device(id: String): InputDevice? {
        val number = id.toIntOrNull() ?: return null
        val device = InputDevice.getDevice(number) ?: return null
        return device.takeIf {
            (it.sources and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD ||
                (it.sources and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK
        }
    }
}
