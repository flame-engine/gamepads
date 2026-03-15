import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/mappings/platform_mapping.dart';

/// Mapping for Android gamepad events.
///
/// Android uses `KeyEvent.keyCodeToString()` for buttons (e.g.,
/// "KEYCODE_BUTTON_A") and `MotionEvent.axisToString()` for axes
/// (e.g., "AXIS_X").
class AndroidMapping extends PlatformMapping {
  static const _buttonMap = <String, GamepadButton>{
    'KEYCODE_BUTTON_A': GamepadButton.a,
    'KEYCODE_BUTTON_B': GamepadButton.b,
    'KEYCODE_BUTTON_X': GamepadButton.x,
    'KEYCODE_BUTTON_Y': GamepadButton.y,
    'KEYCODE_BUTTON_L1': GamepadButton.leftBumper,
    'KEYCODE_BUTTON_R1': GamepadButton.rightBumper,
    'KEYCODE_BUTTON_L2': GamepadButton.leftTrigger,
    'KEYCODE_BUTTON_R2': GamepadButton.rightTrigger,
    'KEYCODE_BUTTON_SELECT': GamepadButton.back,
    'KEYCODE_BUTTON_START': GamepadButton.start,
    'KEYCODE_BUTTON_MODE': GamepadButton.home,
    'KEYCODE_BUTTON_THUMBL': GamepadButton.leftStick,
    'KEYCODE_BUTTON_THUMBR': GamepadButton.rightStick,
    'KEYCODE_DPAD_UP': GamepadButton.dpadUp,
    'KEYCODE_DPAD_DOWN': GamepadButton.dpadDown,
    'KEYCODE_DPAD_LEFT': GamepadButton.dpadLeft,
    'KEYCODE_DPAD_RIGHT': GamepadButton.dpadRight,
  };

  static const _axisMap = <String, GamepadAxis>{
    'AXIS_X': GamepadAxis.leftStickX,
    'AXIS_Y': GamepadAxis.leftStickY,
    'AXIS_Z': GamepadAxis.rightStickX,
    'AXIS_RZ': GamepadAxis.rightStickY,
    'AXIS_LTRIGGER': GamepadAxis.leftTrigger,
    'AXIS_RTRIGGER': GamepadAxis.rightTrigger,
    'AXIS_BRAKE': GamepadAxis.leftTrigger,
    'AXIS_GAS': GamepadAxis.rightTrigger,
  };

  // D-pad hat axes on Android.
  static const _dpadXAxis = 'AXIS_HAT_X';
  static const _dpadYAxis = 'AXIS_HAT_Y';

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
    // Android reports sticks in -1.0 to 1.0 and triggers in 0.0 to 1.0.
    // Y-axis is inverted on Android (up = negative).
    if (axis == GamepadAxis.leftStickY || axis == GamepadAxis.rightStickY) {
      return NormalizedAxis(axis, -value);
    }
    return NormalizedAxis(axis, value);
  }

  @override
  List<NormalizedButton> normalizeDpadAxis(String key, double value) {
    if (key == _dpadXAxis) {
      return [
        NormalizedButton(GamepadButton.dpadLeft, value < 0 ? 1.0 : 0.0),
        NormalizedButton(
          GamepadButton.dpadRight,
          value > 0 ? 1.0 : 0.0,
        ),
      ];
    }
    if (key == _dpadYAxis) {
      return [
        NormalizedButton(
          GamepadButton.dpadDown,
          value > 0 ? 1.0 : 0.0,
        ),
        NormalizedButton(GamepadButton.dpadUp, value < 0 ? 1.0 : 0.0),
      ];
    }
    return const [];
  }
}
