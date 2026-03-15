import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/src/mappings/platform_mapping.dart';

/// Mapping for iOS gamepad events.
///
/// iOS uses GCController API which provides semantic button names like
/// "buttonA", "leftShoulder", etc. and axis names like
/// "leftStick - xAxis", "dpad - yAxis".
class IosMapping extends PlatformMapping {
  static const _buttonMap = <String, GamepadButton>{
    'buttonA': GamepadButton.a,
    'buttonB': GamepadButton.b,
    'buttonX': GamepadButton.x,
    'buttonY': GamepadButton.y,
    'leftShoulder': GamepadButton.leftBumper,
    'rightShoulder': GamepadButton.rightBumper,
    'leftTrigger': GamepadButton.leftTrigger,
    'rightTrigger': GamepadButton.rightTrigger,
    'buttonMenu': GamepadButton.start,
    'buttonOptions': GamepadButton.back,
    'buttonHome': GamepadButton.home,
    'leftThumbstickButton': GamepadButton.leftStick,
    'rightThumbstickButton': GamepadButton.rightStick,
  };

  static const _axisMap = <String, GamepadAxis>{
    'leftStick - xAxis': GamepadAxis.leftStickX,
    'leftStick - yAxis': GamepadAxis.leftStickY,
    'rightStick - xAxis': GamepadAxis.rightStickX,
    'rightStick - yAxis': GamepadAxis.rightStickY,
  };

  // D-pad is reported as analog axes on iOS.
  static const _dpadXAxis = 'dpad - xAxis';
  static const _dpadYAxis = 'dpad - yAxis';

  @override
  NormalizedButton? normalizeButton(String key, double value) {
    final button = _buttonMap[key];
    if (button == null) {
      return null;
    }
    return NormalizedButton(button, value != 0 ? 1.0 : 0.0);
  }

  @override
  NormalizedAxis? normalizeAxis(String key, double value) {
    final axis = _axisMap[key];
    if (axis == null) {
      return null;
    }
    // iOS reports stick values in -1.0 to 1.0 already.
    return NormalizedAxis(axis, value);
  }

  @override
  List<NormalizedButton> normalizeDpadAxis(String key, double value) {
    if (key == _dpadXAxis) {
      return [
        NormalizedButton(GamepadButton.dpadLeft, value < 0 ? 1.0 : 0.0),
        NormalizedButton(GamepadButton.dpadRight, value > 0 ? 1.0 : 0.0),
      ];
    }
    if (key == _dpadYAxis) {
      return [
        NormalizedButton(GamepadButton.dpadDown, value < 0 ? 1.0 : 0.0),
        NormalizedButton(GamepadButton.dpadUp, value > 0 ? 1.0 : 0.0),
      ];
    }
    return [];
  }
}
