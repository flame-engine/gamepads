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

  Future<void> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onGamepadEvent':
        emitGamepadEvent(GamepadEvent.parse(call.args));
      case 'onGamepadConnectionEvent':
        emitGamepadConnectionEvent(GamepadConnectionEvent.parse(call.args));
    }
  }
}
