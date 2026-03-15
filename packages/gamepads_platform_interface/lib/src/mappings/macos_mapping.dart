import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/src/mappings/platform_mapping.dart';

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
  // matching.
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

  // Axis keys: "<sfSymbolsName> - xAxis" or "<sfSymbolsName> - yAxis"
  // The stick element names typically contain "l.joystick" or "r.joystick"
  // or "dpad" patterns.
  static const _leftStickPattern = 'l.joystick';
  static const _rightStickPattern = 'r.joystick';
  static const _dpadPattern = 'dpad';

  @override
  NormalizedButton? normalizeButton(String key, double value) {
    for (final entry in _buttonPatterns.entries) {
      if (key.contains(entry.key)) {
        return NormalizedButton(entry.value, value != 0 ? 1.0 : 0.0);
      }
    }
    return null;
  }

  @override
  NormalizedAxis? normalizeAxis(String key, double value) {
    // macOS reports stick values in -1.0 to 1.0 or 0.0 to 1.0 range.
    if (key.contains(_leftStickPattern)) {
      if (key.endsWith('xAxis')) {
        return NormalizedAxis(GamepadAxis.leftStickX, value);
      }
      if (key.endsWith('yAxis')) {
        return NormalizedAxis(GamepadAxis.leftStickY, value);
      }
    }
    if (key.contains(_rightStickPattern)) {
      if (key.endsWith('xAxis')) {
        return NormalizedAxis(GamepadAxis.rightStickX, value);
      }
      if (key.endsWith('yAxis')) {
        return NormalizedAxis(GamepadAxis.rightStickY, value);
      }
    }
    return null;
  }

  @override
  List<NormalizedButton> normalizeDpadAxis(String key, double value) {
    if (!key.contains(_dpadPattern)) {
      return [];
    }

    if (key.endsWith('xAxis')) {
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
    if (key.endsWith('yAxis')) {
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
    return [];
  }
}
