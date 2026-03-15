library gamepads;

import 'package:gamepads/src/api/normalized_gamepad_event.dart';
import 'package:gamepads/src/gamepad_normalizer.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

class Gamepads {
  Gamepads._();

  static final _platform = GamepadsPlatformInterface.instance;

  /// The normalizer used to convert raw events to normalized events.
  ///
  /// Must be set before accessing [normalizedEvents]. Typically set once
  /// at app startup:
  /// ```dart
  /// Gamepads.normalizer = GamepadNormalizer();
  /// ```
  static GamepadNormalizer? normalizer;

  static Future<List<GamepadController>> list() => _platform.listGamepads();

  static Stream<GamepadEvent> get events => _platform.gamepadEventsStream;

  /// A stream of normalized gamepad events.
  ///
  /// Requires [normalizer] to be set. Events that cannot be normalized
  /// (unrecognized keys) are silently dropped.
  ///
  /// Throws [StateError] if [normalizer] has not been set.
  static Stream<NormalizedGamepadEvent> get normalizedEvents {
    final currentNormalizer = normalizer;
    if (currentNormalizer == null) {
      throw StateError(
        'Gamepads.normalizer must be set before accessing '
        'normalizedEvents. Set it at app startup: '
        'Gamepads.normalizer = GamepadNormalizer(platform: ...)',
      );
    }
    return events.transform(currentNormalizer.transformer);
  }

  static Stream<GamepadEvent> eventsByGamepad(String gamepadId) {
    return events.where((event) => event.gamepadId == gamepadId);
  }
}
