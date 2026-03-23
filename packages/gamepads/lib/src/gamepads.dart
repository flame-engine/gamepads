library gamepads;

import 'package:gamepads/src/api/normalized_gamepad_event.dart';
import 'package:gamepads/src/gamepad_normalizer.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

class Gamepads {
  Gamepads._();

  static final _platform = GamepadsPlatformInterface.instance;

  static GamepadNormalizer? _normalizer;
  static Stream<NormalizedGamepadEvent>? _normalizedEvents;

  /// The normalizer used to convert raw events to normalized events.
  ///
  /// Set automatically when [normalizedEvents] is first accessed.
  /// Override to use a custom normalizer (e.g., for a specific
  /// platform or with a custom mapping):
  /// ```dart
  /// Gamepads.normalizer = GamepadNormalizer.forPlatform(
  ///   GamepadPlatform.linux,
  /// );
  /// ```
  static GamepadNormalizer? get normalizer => _normalizer;
  static set normalizer(GamepadNormalizer? value) {
    _normalizer = value;
    // Invalidate cached stream so next access uses the new normalizer.
    _normalizedEvents = null;
  }

  static Future<List<GamepadController>> list() => _platform.listGamepads();

  static Stream<GamepadEvent> get events => _platform.gamepadEventsStream;

  /// A stream of normalized gamepad events.
  ///
  /// A [GamepadNormalizer] is auto-created on first access using the
  /// current platform. Override [normalizer] before accessing this
  /// stream to use a custom normalizer.
  ///
  /// Events that cannot be normalized (unrecognized keys) are silently
  /// dropped.
  static Stream<NormalizedGamepadEvent> get normalizedEvents {
    if (_normalizedEvents != null) {
      return _normalizedEvents!;
    }
    _normalizer ??= GamepadNormalizer();
    _normalizedEvents = events.transform(_normalizer!.transformer);
    return _normalizedEvents!;
  }

  static Stream<GamepadEvent> eventsByGamepad(String gamepadId) {
    return events.where((event) => event.gamepadId == gamepadId);
  }
}
