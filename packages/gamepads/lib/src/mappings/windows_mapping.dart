import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/mappings/linux_mapping.dart';
import 'package:gamepads/src/mappings/platform_mapping.dart';

/// Mapping for Windows gamepad events.
///
/// Windows uses "a", "b" etc. for buttons and named strings for axes:
/// "leftThumbstickX, "leftThumbstickY", ...
///
/// Default axis mapping (most common for XInput-compatible controllers):
/// - leftThumbstickX: Left stick X (-1 to 1, center 0)
/// - leftThumbstickY: Left stick Y (-1 to 1, center 0)
/// - rightThumbstickX: Left stick X (-1 to 1, center 0)
/// - rightThumbstickY: Left stick Y (-1 to 1, center 0)
/// - leftTrigger: Left trigger (0 to 1)
/// - rightTrigger: Right trigger (0 to 1)
class WindowsMapping extends PlatformMapping {
  final UnknownControllerBehavior _unknownBehavior;
  final _WindowsControllerMapping? _controllerMapping;

  WindowsMapping({
    UnknownControllerBehavior unknownBehavior =
        UnknownControllerBehavior.bestEffort,
  }) : _unknownBehavior = unknownBehavior,
       _controllerMapping =
           unknownBehavior == UnknownControllerBehavior.bestEffort
           ? _WindowsControllerMapping.defaultMapping
           : null;

  @override
  bool get requiresDeviceId => true;

  @override
  PlatformMapping forDevice({int? vendorId, int? productId}) {
    // The Windows GameInput API sends named strings (e.g. "a",
    // "leftThumbstickX") that already match the default mapping.
    // The SDL DB contains numeric-index mappings that don't apply
    // here, so we skip the DB lookup entirely.
    return WindowsMapping(unknownBehavior: _unknownBehavior);
  }

  @override
  NormalizedButton? normalizeButton(String key, double value) {
    final controllerMapping = _controllerMapping;
    if (controllerMapping == null) {
      return null;
    }

    final button = controllerMapping.buttons[key];
    if (button == null) {
      return null;
    }
    return NormalizedButton(button, value != 0 ? 1.0 : 0.0);
  }

  @override
  List<NormalizedAxis> normalizeAxis(String key, double value) {
    final controllerMapping = _controllerMapping;
    if (controllerMapping == null) {
      return const [];
    }

    final axisInfo = controllerMapping.axes[key];
    if (axisInfo == null) {
      return const [];
    }

    final normalized = _normalizeAxisValue(
      value,
      axisInfo.axis,
      axisInfo.min,
      axisInfo.max,
      axisInfo.inverted,
    );
    return [NormalizedAxis(axisInfo.axis, normalized)];
  }

  static double _normalizeAxisValue(
    double value,
    GamepadAxis axis,
    double min,
    double max,
    bool inverted,
  ) {
    final isTrigger =
        axis == GamepadAxis.leftTrigger || axis == GamepadAxis.rightTrigger;

    if (isTrigger) {
      // Normalize from [min, max] to [0.0, 1.0].
      return (value - min) / (max - min);
    }

    // Normalize from [min, max] to [-1.0, 1.0].
    var normalized = 2.0 * (value - min) / (max - min) - 1.0;
    if (inverted) {
      normalized = -normalized;
    }
    return normalized;
  }
}

class _WindowsAxisInfo {
  final GamepadAxis axis;
  final double min;
  final double max;
  final bool inverted;

  const _WindowsAxisInfo(
    this.axis,
    this.min,
    this.max, {
    this.inverted = false,
  });
}

class _WindowsControllerMapping {
  final Map<String, GamepadButton> buttons;
  final Map<String, _WindowsAxisInfo> axes;

  const _WindowsControllerMapping({
    required this.buttons,
    required this.axes,
  });

  /// Default mapping for Xbox-like controllers via the Windows joystick
  /// API.
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
        inverted: true,
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
        inverted: true,
      ),
    },
  );

}
