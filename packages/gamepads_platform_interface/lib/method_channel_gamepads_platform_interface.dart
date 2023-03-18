import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_interface.dart';

class MethodChannelGamepadsPlatformInterface extends GamepadsPlatformInterface {
  final MethodChannel _channel = const MethodChannel('xyz.luan/gamepads');

  MethodChannelGamepadsPlatformInterface() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  @override
  Future<int> getValue() async {
    final result = await _channel.compute<int>('getValue', <String, dynamic>{});
    return result!;
  }

  Future<void> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onGamepadEvent':
        final value = call.getString('value');
        emitGamepadEvent(GamepadEvent(value: value));
        break;
    }
  }

  void emitGamepadEvent(GamepadEvent event) {
    _gamepadEventsStreamController.add(event);
  }

  final StreamController<GamepadEvent> _gamepadEventsStreamController =
      StreamController<GamepadEvent>.broadcast();

  @override
  Stream<GamepadEvent> get gamepadEventsStream =>
      _gamepadEventsStreamController.stream;

  @mustCallSuper
  Future<void> dispose() async {
    _gamepadEventsStreamController.close();
  }
}
