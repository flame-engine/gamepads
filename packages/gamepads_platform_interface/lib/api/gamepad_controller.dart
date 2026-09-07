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
  /// The format is opaque and differs per platform: the device node path on
  /// Linux, a device identifier on Windows, the input device id on Android,
  /// the gamepad index on web, and a per-process counter on iOS and macOS.
  ///
  /// It stays the same for as long as the gamepad is connected, but a gamepad
  /// that reconnects is not guaranteed to get the same identifier back.
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

  StreamSubscription<GamepadEvent>? _subscription;

  GamepadController({
    required this.id,
    required this.name,
    required GamepadsPlatformInterface plugin,
    this.vendorId,
    this.productId,
  }) {
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

  /// Stops listening for new inputs.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
