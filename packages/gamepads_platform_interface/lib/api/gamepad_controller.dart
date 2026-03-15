import 'dart:async';

import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/api/gamepad_state.dart';
import 'package:gamepads_platform_interface/api/normalized_gamepad_state.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

/// Represents a single, currently connected joystick controller (or gamepad).
///
/// By calling the constructor, this object will automatically subscribe to
/// events and update its internal [state]. To stop listening, be sure to call
/// [dispose]. Failing to do so may result in the object leaking memory.
class GamepadController {
  /// A unique identifier for the gamepad controller.
  ///
  /// On Linux, it maps to the file descriptor path.
  /// On macOs and Windows, it's just the index of the connected controller.
  final String id;

  /// A user-facing, platform-dependant name for the gamepad controller.
  final String name;

  final state = GamepadState();

  /// The normalized state of this gamepad, updated automatically when a
  /// [GamepadNormalizer] is provided.
  final normalizedState = NormalizedGamepadState();

  StreamSubscription<GamepadEvent>? _subscription;
  GamepadNormalizer? _normalizer;

  GamepadController({
    required this.id,
    required this.name,
    required GamepadsPlatformInterface plugin,
    GamepadNormalizer? normalizer,
  }) : _normalizer = normalizer {
    _subscription = plugin.eventsByGamepad(id).listen(_handleEvent);
  }

  factory GamepadController.parse(
    Map<dynamic, dynamic> map,
    GamepadsPlatformInterface plugin, {
    GamepadNormalizer? normalizer,
  }) {
    final id = map['id'] as String;
    final name = map['name'] as String;
    return GamepadController(
      id: id,
      name: name,
      plugin: plugin,
      normalizer: normalizer,
    );
  }

  void _handleEvent(GamepadEvent event) {
    state.update(event);
    final normalizer = _normalizer;
    if (normalizer != null) {
      for (final normalized in normalizer.normalize(event)) {
        normalizedState.update(normalized);
      }
    }
  }

  /// Stops listening for new inputs.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
