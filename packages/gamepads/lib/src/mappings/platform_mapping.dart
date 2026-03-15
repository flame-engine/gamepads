import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';

/// Result of normalizing a button input.
class NormalizedButton {
  final GamepadButton button;
  final double value;

  const NormalizedButton(this.button, this.value);
}

/// Result of normalizing an axis input.
class NormalizedAxis {
  final GamepadAxis axis;
  final double value;

  const NormalizedAxis(this.axis, this.value);
}

/// Abstract interface for platform-specific gamepad mappings.
///
/// Each platform provides a concrete implementation that maps raw
/// platform-specific key strings and values to normalized
/// [GamepadButton]/[GamepadAxis] enums and standard value ranges.
abstract class PlatformMapping {
  /// Attempts to normalize a button event.
  ///
  /// Returns `null` if the key is not recognized.
  NormalizedButton? normalizeButton(String key, double value);

  /// Attempts to normalize an analog event.
  ///
  /// Returns `null` if the key is not recognized.
  /// May return a [NormalizedButton] result wrapped as an axis if the
  /// platform reports d-pad as analog.
  NormalizedAxis? normalizeAxis(String key, double value);

  /// Some platforms report d-pad as analog axes. This method handles
  /// converting d-pad axis values to discrete button events.
  ///
  /// Returns a list of button events (e.g., dpadLeft pressed and
  /// dpadRight released when axis goes negative).
  List<NormalizedButton> normalizeDpadAxis(String key, double value) =>
      const [];

  /// Whether this mapping requires VID/PID to select the correct mapping.
  bool get requiresDeviceId => false;

  /// For mappings that require device identification, selects a
  /// controller-specific sub-mapping based on vendor and product IDs.
  ///
  /// Returns the current mapping by default (no-op for platform-default
  /// mappings). Subclasses override to return a device-specific mapping.
  // ignore: avoid_returning_this
  PlatformMapping forDevice({int? vendorId, int? productId}) => this;
}
