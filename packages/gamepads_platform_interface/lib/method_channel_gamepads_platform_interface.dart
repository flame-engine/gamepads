import 'package:flutter/services.dart';
import 'package:gamepads_platform_interface/api/gamepad_connection_event.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_interface.dart';

class MethodChannelGamepadsPlatformInterface extends GamepadsPlatformInterface {
  final MethodChannel _channel = const MethodChannel('xyz.luan/gamepads');

  MethodChannelGamepadsPlatformInterface() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  @override
  Future<List<GamepadController>> listGamepads() async {
    final result = await _channel.compute<List<Object?>>(
      'listGamepads',
      <String, dynamic>{},
    );
    return result!.map((Object? e) {
      return GamepadController.parse(e! as Map<dynamic, dynamic>, this);
    }).toList();
  }

  Future<bool> _rumbleCall(String method, Map<String, Object> arguments) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> hasRumble(String gamepadId) =>
      _rumbleCall('hasRumble', {'gamepadId': gamepadId});

  @override
  Future<bool> stopRumble(String gamepadId) =>
      _rumbleCall('stopRumble', {'gamepadId': gamepadId});

  @override
  Future<bool> rumble(
    String gamepadId, {
    double lowFrequency = 0,
    double highFrequency = 0,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    GamepadsPlatformInterface.validateRumble(
      lowFrequency,
      highFrequency,
      duration,
    );
    if (duration.inMilliseconds == 0 ||
        (lowFrequency == 0 && highFrequency == 0)) {
      return stopRumble(gamepadId);
    }
    return _rumbleCall('rumble', {
      'gamepadId': gamepadId,
      'lowFrequency': lowFrequency,
      'highFrequency': highFrequency,
      'durationMillis': duration.inMilliseconds,
    });
  }

  Future<void> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onGamepadEvent':
        emitGamepadEvent(GamepadEvent.parse(call.args));
      case 'onGamepadConnectionEvent':
        emitGamepadConnectionEvent(GamepadConnectionEvent.parse(call.args));
    }
  }
}
