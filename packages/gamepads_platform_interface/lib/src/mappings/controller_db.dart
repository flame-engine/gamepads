import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/src/mappings/sdl_mapping_parser.dart';

/// A database entry describing how a specific controller maps its raw
/// key indices to standard gamepad buttons and axes.
class ControllerMapping {
  /// Maps raw button key strings to [GamepadButton].
  final Map<String, GamepadButton> buttons;

  /// Maps raw analog key strings to [GamepadAxis].
  final Map<String, GamepadAxis> axes;

  /// Maps raw analog key strings that represent d-pad axes.
  /// The value is `true` for X axis, `false` for Y axis.
  final Map<String, bool> dpadAxes;

  /// Whether the Y-axis values are inverted (negative = up).
  final bool yAxisInverted;

  /// Raw value range for stick axes: [min, max].
  final (double, double)? stickRange;

  /// Raw value range for trigger axes: [min, max].
  final (double, double)? triggerRange;

  const ControllerMapping({
    required this.buttons,
    required this.axes,
    this.dpadAxes = const {},
    this.yAxisInverted = false,
    this.stickRange,
    this.triggerRange,
  });
}

/// Database of controller mappings, keyed by (vendorId, productId).
///
/// Populated by loading SDL GameController DB format strings via
/// [loadSdlMappings]. A minimal built-in fallback mapping is included
/// for use when no SDL database has been loaded.
class ControllerDb {
  ControllerDb._();

  static final _mappings = <(int, int), ControllerMapping>{};

  /// Looks up a controller mapping by vendor and product ID.
  ///
  /// Returns `null` if the controller is not in the database.
  static ControllerMapping? lookup({
    required int vendorId,
    required int productId,
  }) {
    return _mappings[(vendorId, productId)];
  }

  /// Loads controller mappings from an SDL GameController DB format
  /// string.
  ///
  /// The [content] should be the contents of a `gamecontrollerdb.txt`
  /// file. Each line has the format:
  /// ```
  /// GUID,name,a:b0,b:b1,...,platform:Linux,
  /// ```
  ///
  /// Only mappings matching [platform] are loaded (e.g., "Linux" or
  /// "Windows"). If [platform] is null, all entries are loaded.
  ///
  /// Later calls add to (and can override) previously loaded mappings.
  ///
  /// Returns the number of mappings loaded.
  static int loadSdlMappings(String content, {String? platform}) {
    final parsed = SdlMappingParser.parseToDb(
      content,
      platform: platform,
    );
    _mappings.addAll(parsed);
    return parsed.length;
  }

  /// Clears all loaded mappings.
  static void clearMappings() {
    _mappings.clear();
  }

  /// Default Xbox-like mapping used as a best-effort fallback for
  /// unknown controllers on Linux. This is used when no SDL database
  /// entry matches the controller's VID/PID.
  static const defaultMapping = ControllerMapping(
    buttons: {
      '0': GamepadButton.a,
      '1': GamepadButton.b,
      '2': GamepadButton.x,
      '3': GamepadButton.y,
      '4': GamepadButton.leftBumper,
      '5': GamepadButton.rightBumper,
      '6': GamepadButton.back,
      '7': GamepadButton.start,
      '8': GamepadButton.home,
      '9': GamepadButton.leftStick,
      '10': GamepadButton.rightStick,
    },
    axes: {
      '0': GamepadAxis.leftStickX,
      '1': GamepadAxis.leftStickY,
      '2': GamepadAxis.leftTrigger,
      '3': GamepadAxis.rightStickX,
      '4': GamepadAxis.rightStickY,
      '5': GamepadAxis.rightTrigger,
    },
    dpadAxes: {
      '6': true,
      '7': false,
    },
    yAxisInverted: true,
    stickRange: (-32768, 32767),
    triggerRange: (-32768, 32767),
  );
}
