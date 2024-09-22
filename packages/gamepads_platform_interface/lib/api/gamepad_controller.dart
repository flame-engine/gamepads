import 'dart:async';

import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/api/gamepad_state.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

/// Represents a single, currently connected joystick controller (or gamepad).
class GamepadController {
  /// A unique identifier for the gamepad controller.
  ///
  /// On Linux, it maps to the file descriptor path.
  /// On macOs and Windows, it's just the index of the connected controller.
  final String id;

  /// A user-facing, platform-dependant name for the gamepad controller.
  final String name;

  final state = GamepadState();

  StreamSubscription<GamepadEvent>? _subscription;

  GamepadController({
    required this.id,
    required this.name,
    required GamepadsPlatformInterface plugin,
  }) {
    _subscription = plugin.eventsByGamepad(id).listen(state.update);
  }

  factory GamepadController.parse(
    Map<dynamic, dynamic> map,
    GamepadsPlatformInterface plugin,
  ) {
    final id = map['id'] as String;
    final name = map['name'] as String;
    return GamepadController(id: id, name: name, plugin: plugin);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
