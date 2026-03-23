import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/mappings/platform_mapping.dart';

/// Mapping for Windows gamepad events.
///
/// The Windows GameInput API sends named strings for all controllers
/// (e.g. "a", "b", "leftThumbstickX"), so a single default mapping
/// works for every controller. No VID/PID lookup is needed.
///
/// Button keys: "a", "b", "x", "y", "leftShoulder", "rightShoulder",
/// "view", "menu", "leftThumbstick", "rightThumbstick",
/// "dpadUp", "dpadDown", "dpadLeft", "dpadRight"
///
/// Axis keys and ranges:
/// - leftThumbstickX/Y, rightThumbstickX/Y: -1.0 to 1.0
/// - leftTrigger, rightTrigger: 0.0 to 1.0
class WindowsMapping extends PlatformMapping {
  static const _mapping = _WindowsControllerMapping.defaultMapping;

  @override
  NormalizedButton? normalizeButton(String key, double value) {
    final button = _mapping.buttons[key];
    if (button == null) {
      return null;
    }
    return NormalizedButton(button, value != 0 ? 1.0 : 0.0);
  }

  @override
  List<NormalizedAxis> normalizeAxis(String key, double value) {
    final axisInfo = _mapping.axes[key];
    if (axisInfo == null) {
      return const [];
    }

    final normalized = _normalizeAxisValue(
      value,
      axisInfo.axis,
      axisInfo.min,
      axisInfo.max,
    );
    return [NormalizedAxis(axisInfo.axis, normalized)];
  }

  static double _normalizeAxisValue(
    double value,
    GamepadAxis axis,
    double min,
    double max,
  ) {
    final isTrigger =
        axis == GamepadAxis.leftTrigger || axis == GamepadAxis.rightTrigger;

    if (isTrigger) {
      // Normalize from [min, max] to [0.0, 1.0].
      return (value - min) / (max - min);
    }

    // Normalize from [min, max] to [-1.0, 1.0].
    return 2.0 * (value - min) / (max - min) - 1.0;
  }
}

class _WindowsAxisInfo {
  final GamepadAxis axis;
  final double min;
  final double max;

  const _WindowsAxisInfo(this.axis, this.min, this.max);
}

class _WindowsControllerMapping {
  final Map<String, GamepadButton> buttons;
  final Map<String, _WindowsAxisInfo> axes;

  const _WindowsControllerMapping({
    required this.buttons,
    required this.axes,
  });

  /// Default mapping matching the GameInput API key strings.
  static const defaultMapping = _WindowsControllerMapping(
    buttons: {
      'a': GamepadButton.a,
      'b': GamepadButton.b,
      'x': GamepadButton.x,
      'y': GamepadButton.y,
      'dpadUp': GamepadButton.dpadUp,
      'dpadRight': GamepadButton.dpadRight,
      'dpadDown': GamepadButton.dpadDown,
      'dpadLeft': GamepadButton.dpadLeft,
      'leftShoulder': GamepadButton.leftBumper,
      'rightShoulder': GamepadButton.rightBumper,
      'view': GamepadButton.back,
      'menu': GamepadButton.start,
      'leftThumbstick': GamepadButton.leftStick,
      'rightThumbstick': GamepadButton.rightStick,
    },
    axes: {
      'leftThumbstickX': _WindowsAxisInfo(
        GamepadAxis.leftStickX,
        -1.0,
        1.0,
      ),
      'leftThumbstickY': _WindowsAxisInfo(
        GamepadAxis.leftStickY,
        -1.0,
        1.0,
      ),
      'leftTrigger': _WindowsAxisInfo(
        GamepadAxis.leftTrigger,
        0.0,
        1.0,
      ),
      'rightThumbstickX': _WindowsAxisInfo(
        GamepadAxis.rightStickX,
        -1.0,
        1.0,
      ),
      'rightThumbstickY': _WindowsAxisInfo(
        GamepadAxis.rightStickY,
        -1.0,
        1.0,
      ),
      'rightTrigger': _WindowsAxisInfo(
        GamepadAxis.rightTrigger,
        0.0,
        1.0,
      ),
    },
  );
}
