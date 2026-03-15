import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/src/mappings/platform_mapping.dart';

/// Mapping for Web gamepad events using the W3C Standard Gamepad mapping.
///
/// The Web Gamepad API uses numeric indices for buttons and axes.
/// The current web plugin sends keys as "button N" and "analog N".
///
/// W3C Standard Gamepad button mapping:
/// https://w3c.github.io/gamepad/#remapping
///
/// Button indices:
///   0: A (bottom), 1: B (right), 2: X (left), 3: Y (top)
///   4: Left bumper, 5: Right bumper
///   6: Left trigger, 7: Right trigger
///   8: Back/Select, 9: Start
///   10: Left stick click, 11: Right stick click
///   12: D-pad up, 13: D-pad down, 14: D-pad left, 15: D-pad right
///   16: Home/Guide
///
/// Axis indices:
///   0: Left stick X, 1: Left stick Y
///   2: Right stick X, 3: Right stick Y
class WebStandardMapping extends PlatformMapping {
  static const _buttonMap = <String, GamepadButton>{
    'button 0': GamepadButton.a,
    'button 1': GamepadButton.b,
    'button 2': GamepadButton.x,
    'button 3': GamepadButton.y,
    'button 4': GamepadButton.leftBumper,
    'button 5': GamepadButton.rightBumper,
    'button 6': GamepadButton.leftTrigger,
    'button 7': GamepadButton.rightTrigger,
    'button 8': GamepadButton.back,
    'button 9': GamepadButton.start,
    'button 10': GamepadButton.leftStick,
    'button 11': GamepadButton.rightStick,
    'button 12': GamepadButton.dpadUp,
    'button 13': GamepadButton.dpadDown,
    'button 14': GamepadButton.dpadLeft,
    'button 15': GamepadButton.dpadRight,
    'button 16': GamepadButton.home,
  };

  static const _axisMap = <String, GamepadAxis>{
    'analog 0': GamepadAxis.leftStickX,
    'analog 1': GamepadAxis.leftStickY,
    'analog 2': GamepadAxis.rightStickX,
    'analog 3': GamepadAxis.rightStickY,
  };

  @override
  NormalizedButton? normalizeButton(String key, double value) {
    final button = _buttonMap[key];
    if (button == null) {
      return null;
    }
    // Web API reports button values as 0.0 to 1.0.
    // For triggers the value can be analog, for others it's 0 or 1.
    return NormalizedButton(button, value != 0 ? 1.0 : 0.0);
  }

  @override
  NormalizedAxis? normalizeAxis(String key, double value) {
    final axis = _axisMap[key];
    if (axis == null) {
      return null;
    }
    // Web reports sticks in -1.0 to 1.0.
    // Y-axis is inverted in the Web Gamepad API (up = negative).
    if (axis == GamepadAxis.leftStickY ||
        axis == GamepadAxis.rightStickY) {
      return NormalizedAxis(axis, -value);
    }
    return NormalizedAxis(axis, value);
  }
}
