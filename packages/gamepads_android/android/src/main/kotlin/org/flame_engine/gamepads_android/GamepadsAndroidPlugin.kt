package org.flame_engine.gamepads_android

import androidx.annotation.NonNull
import android.app.Activity
import android.content.Context
import android.hardware.input.InputManager
import android.util.Log
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.concurrent.thread

class GamepadsAndroidPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  companion object {
    private const val TAG = "GamepadsAndroidPlugin"
  }
  private lateinit var channel : MethodChannel
  private lateinit var devices : DeviceListener
  private lateinit var events : EventListener

  // Decor view we attach an OnGenericMotionListener to, plus the listener
  // itself, so analog motion is captured even when the focused view (e.g.
  // FlutterView) consumes joystick MotionEvents before they bubble up to
  // Activity.dispatchGenericMotionEvent. Kept for removal on detach.
  private var motionDecorView: View? = null
  private var genericMotionListener: View.OnGenericMotionListener? = null

  private fun listGamepads(): List<Map<String, String>>  {
    return devices.getDevices().map { device ->
      mapOf(
        "id" to device.key.toString(),
        "name" to device.value.name
      )
    }
  }

  // FlutterPlugin
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "xyz.luan/gamepads")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "listGamepads") {
      result.success(listGamepads())
    } else {
      result.notImplemented()
    }
  }

  // Activity Aware
  override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
    onAttachedToActivityShared(activityPluginBinding.activity)
  }

  fun onAttachedToActivityShared(activity: Activity) {
    val compatibleActivity = activity as GamepadsCompatibleActivity
    devices = DeviceListener { compatibleActivity.isGamepadsInputDevice(it) }
    events = EventListener()
    compatibleActivity.registerInputDeviceListener(devices, handler = null)
    compatibleActivity.registerKeyEventHandler { event ->
      if (devices.containsKey(event.deviceId)) {
        events.onKeyEvent(event, channel)
      } else {
        false
      }
     }
    compatibleActivity.registerMotionEventHandler { event ->
      if (devices.containsKey(event.deviceId)) {
        events.onMotionEvent(event, channel)
      } else {
        false
      }
    }

    // In an embedded FlutterActivity the focused view (FlutterView/
    // FlutterSurfaceView) consumes joystick MotionEvents, so they never reach
    // Activity.dispatchGenericMotionEvent and the handler above is never
    // invoked for analog axes. Attaching an OnGenericMotionListener to the
    // decor view captures them at the view layer. Duplicate emissions (if both
    // paths fire) are de-duplicated by EventListener's per-axis threshold.
    val listener = View.OnGenericMotionListener { _, event ->
      if (devices.containsKey(event.deviceId)) {
        events.onMotionEvent(event, channel)
      } else {
        false
      }
    }
    val decorView = activity.window?.decorView
    decorView?.setOnGenericMotionListener(listener)
    motionDecorView = decorView
    genericMotionListener = listener
  }

  override fun onDetachedFromActivity() {
    // Remove the decor-view motion listener to avoid leaking the activity.
    if (genericMotionListener != null) {
      motionDecorView?.setOnGenericMotionListener(null)
    }
    motionDecorView = null
    genericMotionListener = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // No-op
  }

  override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
    onAttachedToActivityShared(activityPluginBinding.activity)
  }
}
