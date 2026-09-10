import 'dart:async';

import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/api/gamepad_state.dart';
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

  /// The USB vendor ID of the controller, if available.
  ///
  /// Always `null` on macOS and iOS, where `GCController` does not expose it.
  final int? vendorId;

  /// The USB product ID of the controller, if available.
  ///
  /// Always `null` on macOS and iOS, where `GCController` does not expose it.
  final int? productId;

  final state = GamepadState();
  final GamepadsPlatformInterface _platform;

  StreamSubscription<GamepadEvent>? _subscription;

  GamepadController({
    required this.id,
    required this.name,
    required GamepadsPlatformInterface plugin,
    this.vendorId,
    this.productId,
  }) : _platform = plugin {
    _subscription = plugin.eventsByGamepad(id).listen(state.update);
  }

  factory GamepadController.parse(
    Map<dynamic, dynamic> map,
    GamepadsPlatformInterface plugin,
  ) {
    final id = map['id'] as String;
    final name = map['name'] as String;
    final vendorId = map['vendorId'] as int?;
    final productId = map['productId'] as int?;
    return GamepadController(
      id: id,
      name: name,
      plugin: plugin,
      vendorId: vendorId,
      productId: productId,
    );
  }

  /// Whether this controller currently supports vibration.
  Future<bool> hasRumble() => _platform.hasRumble(id);

  /// Replaces the current vibration with a finite dual-motor effect.
  /// Zero amplitudes or zero duration stop it.
  /// Unsupported devices return false.
  Future<bool> rumble({
    double lowFrequency = 0,
    double highFrequency = 0,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    GamepadsPlatformInterface.validateRumble(
      lowFrequency,
      highFrequency,
      duration,
    );
    return _platform.rumble(
      id,
      lowFrequency: lowFrequency,
      highFrequency: highFrequency,
      duration: duration,
    );
  }

  Future<bool> stopRumble() => _platform.stopRumble(id);

  /// Stops listening for new inputs.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
