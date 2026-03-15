import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/src/mappings/controller_db.dart';
import 'package:gamepads_platform_interface/src/mappings/linux_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/platform_mapping.dart';

/// Mapping for Windows gamepad events.
///
/// Windows uses "button-N" for buttons and named strings for axes:
/// "dwXpos", "dwYpos", "dwZpos", "dwRpos", "dwUpos", "dwVpos", "pov".
///
/// The button indices depend on the controller, so VID/PID is needed for
/// accurate mapping. The axis names are from the Windows joyGetPosEx API.
///
/// Default axis mapping (most common for XInput-compatible controllers):
/// - dwXpos: Left stick X (0-65535, center 32767)
/// - dwYpos: Left stick Y (0-65535, center 32767, inverted)
/// - dwZpos: Triggers combined or left trigger
/// - dwRpos: Right stick Y (0-65535, center 32767, inverted)
/// - dwUpos: Right stick X (0-65535, center 32767)
/// - dwVpos: Right trigger
/// - pov: D-pad (angle in degrees * 100, -1 = centered)
class WindowsMapping extends PlatformMapping {
  final UnknownControllerBehavior _unknownBehavior;
  _WindowsControllerMapping? _controllerMapping;

  WindowsMapping({
    UnknownControllerBehavior unknownBehavior =
        UnknownControllerBehavior.bestEffort,
  }) : _unknownBehavior = unknownBehavior;

  @override
  bool get requiresDeviceId => true;

  @override
  PlatformMapping forDevice({int? vendorId, int? productId}) {
    final mapping = WindowsMapping(unknownBehavior: _unknownBehavior);
    if (vendorId != null && productId != null) {
      final dbMapping = ControllerDb.lookup(
        vendorId: vendorId,
        productId: productId,
      );
      if (dbMapping != null) {
        mapping._controllerMapping =
            _WindowsControllerMapping.fromDb(dbMapping);
      }
    }
    if (mapping._controllerMapping == null &&
        _unknownBehavior == UnknownControllerBehavior.bestEffort) {
      mapping._controllerMapping =
          _WindowsControllerMapping.defaultMapping;
    }
    return mapping;
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
  NormalizedAxis? normalizeAxis(String key, double value) {
    final controllerMapping = _controllerMapping;
    if (controllerMapping == null) {
      return null;
    }

    // Handle POV/d-pad specially — it's not a true axis.
    if (key == 'pov') {
      return null;
    }

    final axisInfo = controllerMapping.axes[key];
    if (axisInfo == null) {
      return null;
    }

    final normalized = _normalizeAxisValue(
      value,
      axisInfo.axis,
      axisInfo.min,
      axisInfo.max,
      axisInfo.inverted,
    );
    return NormalizedAxis(axisInfo.axis, normalized);
  }

  @override
  List<NormalizedButton> normalizeDpadAxis(String key, double value) {
    if (key != 'pov') {
      return const [];
    }

    // POV is reported as an angle in hundredths of degrees.
    // -1 (or 65535) = centered, 0 = up, 9000 = right, 18000 = down,
    // 27000 = left. Diagonals are intermediate values.
    final pov = value.toInt();
    if (pov < 0 || pov > 36000) {
      // Centered — all d-pad buttons released.
      return [
        const NormalizedButton(GamepadButton.dpadUp, 0.0),
        const NormalizedButton(GamepadButton.dpadRight, 0.0),
        const NormalizedButton(GamepadButton.dpadDown, 0.0),
        const NormalizedButton(GamepadButton.dpadLeft, 0.0),
      ];
    }

    return [
      NormalizedButton(
        GamepadButton.dpadUp,
        (pov >= 31500 || pov <= 4500) ? 1.0 : 0.0,
      ),
      NormalizedButton(
        GamepadButton.dpadRight,
        (pov >= 4500 && pov <= 13500) ? 1.0 : 0.0,
      ),
      NormalizedButton(
        GamepadButton.dpadDown,
        (pov >= 13500 && pov <= 22500) ? 1.0 : 0.0,
      ),
      NormalizedButton(
        GamepadButton.dpadLeft,
        (pov >= 22500 && pov <= 31500) ? 1.0 : 0.0,
      ),
    ];
  }

  static double _normalizeAxisValue(
    double value,
    GamepadAxis axis,
    double min,
    double max,
    bool inverted,
  ) {
    final isTrigger = axis == GamepadAxis.leftTrigger ||
        axis == GamepadAxis.rightTrigger;

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
      'button-0': GamepadButton.a,
      'button-1': GamepadButton.b,
      'button-2': GamepadButton.x,
      'button-3': GamepadButton.y,
      'button-4': GamepadButton.leftBumper,
      'button-5': GamepadButton.rightBumper,
      'button-6': GamepadButton.back,
      'button-7': GamepadButton.start,
      'button-8': GamepadButton.leftStick,
      'button-9': GamepadButton.rightStick,
    },
    axes: {
      'dwXpos': _WindowsAxisInfo(
        GamepadAxis.leftStickX,
        0,
        65535,
      ),
      'dwYpos': _WindowsAxisInfo(
        GamepadAxis.leftStickY,
        0,
        65535,
        inverted: true,
      ),
      'dwZpos': _WindowsAxisInfo(
        GamepadAxis.leftTrigger,
        0,
        65535,
      ),
      'dwRpos': _WindowsAxisInfo(
        GamepadAxis.rightStickY,
        0,
        65535,
        inverted: true,
      ),
      'dwUpos': _WindowsAxisInfo(
        GamepadAxis.rightStickX,
        0,
        65535,
      ),
      'dwVpos': _WindowsAxisInfo(
        GamepadAxis.rightTrigger,
        0,
        65535,
      ),
    },
  );

  // ignore: avoid_unused_constructor_parameters
  factory _WindowsControllerMapping.fromDb(ControllerMapping db) {
    // For Windows, we primarily use the default mapping since the Windows
    // joystick API normalizes button indices. The DB mapping is used for
    // button name resolution.
    return defaultMapping;
  }
}
