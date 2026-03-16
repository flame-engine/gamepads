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
/// - Xbox: "a.circle" / "b.circle" / "x.circle" / "y.circle" - face buttons
/// - DualSense: "xmark.circle" / "circle.circle" / "square.circle" /
///   "triangle.circle" - face buttons
/// - PS/Xbox: "l1.rectangle" / "lb.rectangle" - left bumper
/// - PS/Xbox: "r1.rectangle" / "rb.rectangle" - right bumper
/// - Nintendo: "l.rectangle.roundedbottom" / "r.rectangle.roundedbottom"
/// - PS/Xbox: "l2.rectangle" / "lt.rectangle" - left trigger
/// - PS/Xbox: "r2.rectangle" / "rt.rectangle" - right trigger
/// - Nintendo: "zl.rectangle.roundedtop" / "zr.rectangle.roundedtop"
/// - "line.3.horizontal.circle" / "plus.circle" - menu/start
/// - "capsule.portrait" / "minus.circle" - back/select
/// - "rectangle.fill.on.rectangle.fill.circle" / "square.and.arrow.up" - share
/// - "house.circle" - home
/// - "l.joystick.press.down" / "l.joystick.down" - left stick click
/// - "r.joystick.press.down" / "r.joystick.down" - right stick click
class MacosMapping extends PlatformMapping {
  // SF Symbols names can vary by controller, so we use contains-based
  // matching on first encounter, then cache the result.
  static const _buttonPatterns = <String, GamepadButton>{
    // Xbox-style face buttons
    'a.circle': GamepadButton.a,
    'b.circle': GamepadButton.b,
    'x.circle': GamepadButton.x,
    'y.circle': GamepadButton.y,
    // PlayStation-style face buttons (DualSense SF Symbols)
    'xmark.circle': GamepadButton.a,
    'circle.circle': GamepadButton.b,
    'square.circle': GamepadButton.x,
    'triangle.circle': GamepadButton.y,
    // PlayStation-style: l1/r1, Xbox-style: lb/rb
    // Nintendo-style: l.rectangle/r.rectangle
    'l1.rectangle': GamepadButton.leftBumper,
    'r1.rectangle': GamepadButton.rightBumper,
    'lb.rectangle': GamepadButton.leftBumper,
    'rb.rectangle': GamepadButton.rightBumper,
    'l.rectangle.roundedbottom': GamepadButton.leftBumper,
    'r.rectangle.roundedbottom': GamepadButton.rightBumper,
    // PlayStation-style: l2/r2, Xbox-style: lt/rt
    // Nintendo-style: zl/zr
    'l2.rectangle': GamepadButton.leftTrigger,
    'r2.rectangle': GamepadButton.rightTrigger,
    'lt.rectangle': GamepadButton.leftTrigger,
    'rt.rectangle': GamepadButton.rightTrigger,
    'zl.rectangle': GamepadButton.leftTrigger,
    'zr.rectangle': GamepadButton.rightTrigger,
    // Menu/start: "line.3.horizontal", "line.horizontal.3", "plus.circle"
    'line.3.horizontal': GamepadButton.start,
    'line.horizontal.3': GamepadButton.start,
    'plus.circle': GamepadButton.start,
    // Back/select/share
    'capsule.portrait': GamepadButton.back,
    'minus.circle': GamepadButton.back,
    'rectangle.fill.on.rectangle.fill': GamepadButton.back,
    'square.and.arrow.up': GamepadButton.back,
    'house': GamepadButton.home,
    // Stick clicks: "l.joystick.press" or "l.joystick.down"
    'l.joystick.press': GamepadButton.leftStick,
    'r.joystick.press': GamepadButton.rightStick,
    'l.joystick.down': GamepadButton.leftStick,
    'r.joystick.down': GamepadButton.rightStick,
  };

  // Trigger patterns for analog trigger axes.
  // PlayStation-style: l2/r2, Xbox-style: lt/rt, Nintendo-style: zl/zr
  static const _triggerPatterns = <String, GamepadAxis>{
    'l2.rectangle': GamepadAxis.leftTrigger,
    'r2.rectangle': GamepadAxis.rightTrigger,
    'lt.rectangle': GamepadAxis.leftTrigger,
    'rt.rectangle': GamepadAxis.rightTrigger,
    'zl.rectangle': GamepadAxis.leftTrigger,
    'zr.rectangle': GamepadAxis.rightTrigger,
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
  List<NormalizedAxis> normalizeAxis(String key, double value) {
    if (!_axisCache.containsKey(key)) {
      _axisCache[key] = _findAxis(key);
    }
    final axis = _axisCache[key];
    if (axis == null) {
      return const [];
    }
    return [NormalizedAxis(axis, value)];
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
    // Triggers are reported as analog with their SF Symbol name.
    for (final entry in _triggerPatterns.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
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
