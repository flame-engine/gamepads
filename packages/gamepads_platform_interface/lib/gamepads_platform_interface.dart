import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads_platform_interface/api/gamepad_connection_event.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GamepadsPlatformInterface extends PlatformInterface {
  static final Object _token = Object();

  GamepadsPlatformInterface() : super(token: _token);

  /// The default instance of [GamepadsPlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelGamepadsPlatformInterface].
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [GamepadsPlatformInterface] when they register
  /// themselves.
  static GamepadsPlatformInterface instance =
      MethodChannelGamepadsPlatformInterface();

  final StreamController<GamepadEvent> _gamepadEventsStreamController =
      StreamController<GamepadEvent>.broadcast();

  final StreamController<GamepadConnectionEvent>
  _gamepadConnectionEventsStreamController =
      StreamController<GamepadConnectionEvent>.broadcast();

  Future<List<GamepadController>> listGamepads();

  /// Whether the device currently exposes a usable rumble actuator.
  Future<bool> hasRumble(String gamepadId) async => false;

  /// Replaces the current effect. Intensities are in [0, 1]; duration is
  /// limited to 30 seconds. Returns false when unavailable or rejected.
  /// A true result means accepted, not that physical feedback was verified.
  Future<bool> rumble(
    String gamepadId, {
    double lowFrequency = 0,
    double highFrequency = 0,
    Duration duration = const Duration(milliseconds: 500),
  }) async => false;

  /// Stops this device immediately without affecting other controllers.
  Future<bool> stopRumble(String gamepadId) async => false;

  static void validateRumble(double low, double high, Duration duration) {
    if (!low.isFinite ||
        low < 0 ||
        low > 1 ||
        !high.isFinite ||
        high < 0 ||
        high > 1 ||
        duration < Duration.zero ||
        duration > const Duration(seconds: 30)) {
      throw ArgumentError(
        'Rumble requires intensities in [0, 1] and a duration of 0–30 seconds',
      );
    }
  }

  Stream<GamepadEvent> get gamepadEventsStream =>
      _gamepadEventsStreamController.stream;

  Stream<GamepadEvent> eventsByGamepad(String gamepadId) =>
      gamepadEventsStream.where((event) => event.gamepadId == gamepadId);

  /// A stream of gamepads being connected to and disconnected from the device.
  Stream<GamepadConnectionEvent> get gamepadConnectionEventsStream =>
      _gamepadConnectionEventsStreamController.stream;

  void emitGamepadEvent(GamepadEvent event) {
    _gamepadEventsStreamController.add(event);
  }

  void emitGamepadConnectionEvent(GamepadConnectionEvent event) {
    _gamepadConnectionEventsStreamController.add(event);
  }

  @mustCallSuper
  Future<void> dispose() async {
    await _gamepadEventsStreamController.close();
    await _gamepadConnectionEventsStreamController.close();
  }
}
