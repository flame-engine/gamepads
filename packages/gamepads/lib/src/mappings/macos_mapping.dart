import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/mappings/platform_mapping.dart';

/// Mapping for macOS gamepad events.
///
/// macOS uses GCController API with SF Symbols names for buttons.
/// Button names look like "a.circle", "b.circle", etc.
/// Axis names are constructed as
/// "`<element.sfSymbolsName>` - xAxis/yAxis".
///
/// Common SF Symbol button names observed:
/// - "a.circle" / "b.circle" / "x.circle" / "y.circle" - face buttons
/// - "l1.rectangle.roundedbottom" - left bumper
/// - "r1.rectangle.roundedbottom" - right bumper
/// - "l2.rectangle.roundedtop" - left trigger
/// - "r2.rectangle.roundedtop" - right trigger
/// - "line.3.horizontal.circle" - menu/start
/// - "circle.circle" - options/back
/// - "house.circle" - home
/// - "l.joystick.press.down" - left stick click
/// - "r.joystick.press.down" - right stick click
class MacosMapping extends PlatformMapping {
  // SF Symbols names can vary by controller, so we use contains-based
  // matching on first encounter, then cache the result.
  static const _buttonPatterns = <String, GamepadButton>{
    'a.circle': GamepadButton.a,
    'b.circle': GamepadButton.b,
    'x.circle': GamepadButton.x,
    'y.circle': GamepadButton.y,
    'l1.rectangle': GamepadButton.leftBumper,
    'r1.rectangle': GamepadButton.rightBumper,
    'l2.rectangle': GamepadButton.leftTrigger,
    'r2.rectangle': GamepadButton.rightTrigger,
    'line.3.horizontal': GamepadButton.start,
    'circle.circle': GamepadButton.back,
    'house': GamepadButton.home,
    'l.joystick.press': GamepadButton.leftStick,
    'r.joystick.press': GamepadButton.rightStick,
  };

  static const _leftStickPattern = 'l.joystick';
  static const _rightStickPattern = 'r.joystick';
  static const _dpadPattern = 'dpad';

  // Caches for resolved key → result mappings, avoiding repeated
  // pattern scans for keys already seen.
  final _buttonCache = <String, GamepadButton?>{};
  final _axisCache = <String, GamepadAxis?>{};

  // Tracks whether a key is a d-pad axis (true = X, false = Y,
  // absent = not d-pad).
  final _dpadAxisCache = <String, bool?>{};

  @override
  NormalizedButton? normalizeButton(String key, double value) {
    if (!_buttonCache.containsKey(key)) {
      _buttonCache[key] = _findButton(key);
    }
    final button = _buttonCache[key];
    if (button == null) {
      return null;
    }
    return NormalizedButton(button, value != 0 ? 1.0 : 0.0);
  }

  static GamepadButton? _findButton(String key) {
    for (final entry in _buttonPatterns.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  NormalizedAxis? normalizeAxis(String key, double value) {
    if (!_axisCache.containsKey(key)) {
      _axisCache[key] = _findAxis(key);
    }
    final axis = _axisCache[key];
    if (axis == null) {
      return null;
    }
    return NormalizedAxis(axis, value);
  }

  static GamepadAxis? _findAxis(String key) {
    if (key.contains(_leftStickPattern)) {
      if (key.endsWith('xAxis')) {
        return GamepadAxis.leftStickX;
      }
      if (key.endsWith('yAxis')) {
        return GamepadAxis.leftStickY;
      }
    }
    if (key.contains(_rightStickPattern)) {
      if (key.endsWith('xAxis')) {
        return GamepadAxis.rightStickX;
      }
      if (key.endsWith('yAxis')) {
        return GamepadAxis.rightStickY;
      }
    }
    return null;
  }

  @override
  List<NormalizedButton> normalizeDpadAxis(String key, double value) {
    if (!_dpadAxisCache.containsKey(key)) {
      _dpadAxisCache[key] = _findDpadAxis(key);
    }
    final isXAxis = _dpadAxisCache[key];
    if (isXAxis == null) {
      return const [];
    }

    if (isXAxis) {
      return [
        NormalizedButton(
          GamepadButton.dpadLeft,
          value < 0 ? 1.0 : 0.0,
        ),
        NormalizedButton(
          GamepadButton.dpadRight,
          value > 0 ? 1.0 : 0.0,
        ),
      ];
    }
    return [
      NormalizedButton(
        GamepadButton.dpadDown,
        value < 0 ? 1.0 : 0.0,
      ),
      NormalizedButton(
        GamepadButton.dpadUp,
        value > 0 ? 1.0 : 0.0,
      ),
    ];
  }

  static bool? _findDpadAxis(String key) {
    if (!key.contains(_dpadPattern)) {
      return null;
    }
    if (key.endsWith('xAxis')) {
      return true;
    }
    if (key.endsWith('yAxis')) {
      return false;
    }
    return null;
  }
}
