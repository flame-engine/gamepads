import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/mappings/controller_database.dart';
import 'package:gamepads/src/mappings/platform_mapping.dart';

/// Mapping for Linux gamepad events.
///
/// Linux uses numeric indices as strings (e.g., "0", "1", "2") for both
/// buttons and axes. The mapping depends on the specific controller hardware,
/// so this class requires VID/PID to select the correct mapping from the
/// controller database.
///
/// When [UnknownControllerBehavior.bestEffort] is used, falls back to a
/// default Xbox-like mapping for unrecognized controllers.
class LinuxMapping extends PlatformMapping {
  final UnknownControllerBehavior _unknownBehavior;
  ControllerMapping? _controllerMapping;

  LinuxMapping({
    UnknownControllerBehavior unknownBehavior =
        UnknownControllerBehavior.bestEffort,
  }) : _unknownBehavior = unknownBehavior;

  @override
  bool get requiresDeviceId => true;

  @override
  PlatformMapping forDevice({int? vendorId, int? productId}) {
    final mapping = LinuxMapping(unknownBehavior: _unknownBehavior);
    if (vendorId != null && productId != null) {
      mapping._controllerMapping = ControllerDatabase.lookup(
        vendorId: vendorId,
        productId: productId,
      );
    }
    if (mapping._controllerMapping == null &&
        _unknownBehavior == UnknownControllerBehavior.bestEffort) {
      mapping._controllerMapping = ControllerDatabase.defaultMapping;
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

    final axis = controllerMapping.axes[key];
    if (axis == null) {
      return null;
    }

    final normalized = _normalizeValue(axis, value, controllerMapping);
    return NormalizedAxis(axis, normalized);
  }

  @override
  List<NormalizedButton> normalizeDpadAxis(String key, double value) {
    final controllerMapping = _controllerMapping;
    if (controllerMapping == null) {
      return const [];
    }

    final isXAxis = controllerMapping.dpadAxes[key];
    if (isXAxis == null) {
      return const [];
    }

    // Linux d-pad axis values: -32768 to 32767 or -1 to 1 depending on
    // driver.
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
    } else {
      // Y-axis: negative = up on Linux
      return [
        NormalizedButton(
          GamepadButton.dpadUp,
          value < 0 ? 1.0 : 0.0,
        ),
        NormalizedButton(
          GamepadButton.dpadDown,
          value > 0 ? 1.0 : 0.0,
        ),
      ];
    }
  }

  double _normalizeValue(
    GamepadAxis axis,
    double value,
    ControllerMapping controllerMapping,
  ) {
    final isTrigger =
        axis == GamepadAxis.leftTrigger || axis == GamepadAxis.rightTrigger;
    final isYAxis =
        axis == GamepadAxis.leftStickY || axis == GamepadAxis.rightStickY;

    if (isTrigger) {
      final range = controllerMapping.triggerRange;
      if (range != null) {
        // Normalize trigger from [min, max] to [0.0, 1.0].
        final (min, max) = range;
        return (value - min) / (max - min);
      }
      return value;
    }

    final range = controllerMapping.stickRange;
    if (range != null) {
      // Normalize stick from [min, max] to [-1.0, 1.0].
      final (min, max) = range;
      final normalized = 2.0 * (value - min) / (max - min) - 1.0;
      if (controllerMapping.yAxisInverted && isYAxis) {
        return -normalized;
      }
      return normalized;
    }

    if (controllerMapping.yAxisInverted && isYAxis) {
      return -value;
    }
    return value;
  }
}

/// Behavior when encountering an unknown controller (no VID/PID match).
enum UnknownControllerBehavior {
  /// Return `null` for normalized fields — only exact matches are accepted.
  strict,

  /// Fall back to a default Xbox-like mapping.
  bestEffort,
}
