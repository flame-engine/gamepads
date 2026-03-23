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
///
/// **Y-axis convention**: Normalized stick Y values use up = +1.0,
/// down = -1.0. Platforms where the native API reports the opposite
/// (e.g., iOS, Android, Web) must negate Y in their [normalizeAxis].
/// macOS GCController already reports up = positive natively, so no
/// inversion is needed there. Linux/Windows handle inversion via the
/// `yAxisInverted` flag in `ControllerMapping`.
abstract class PlatformMapping {
  /// Attempts to normalize a button event.
  ///
  /// Returns `null` if the key is not recognized.
  NormalizedButton? normalizeButton(String key, double value);

  /// Attempts to normalize an analog event.
  ///
  /// Returns a list of normalized axis results. Most events produce
  /// a single result, but split-axis mappings (e.g., combined
  /// trigger axis) can produce two results.
  ///
  /// Returns an empty list if the key is not recognized.
  List<NormalizedAxis> normalizeAxis(String key, double value);

  /// Some platforms report d-pad as analog axes. This method handles
  /// converting d-pad axis values to discrete button events.
  ///
  /// Returns a list of button events (e.g., dpadLeft pressed and
  /// dpadRight released when axis goes negative).
  List<NormalizedButton> normalizeDpadAxis(String key, double value) =>
      const [];

  /// Whether this mapping requires VID/PID to select the correct
  /// mapping.
  bool get requiresDeviceId => false;

  /// For mappings that require device identification, selects a
  /// controller-specific sub-mapping based on vendor and product IDs.
  ///
  /// Returns the current mapping by default (no-op for
  /// platform-default mappings). Subclasses override to return a
  /// device-specific mapping.
  // ignore: avoid_returning_this
  PlatformMapping forDevice({int? vendorId, int? productId}) => this;
}
