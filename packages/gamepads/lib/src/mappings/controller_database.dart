import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/gamepad_normalizer.dart';
import 'package:gamepads/src/mappings/data/gamecontrollerdb_data.dart';
import 'package:gamepads/src/mappings/sdl_mapping_parser.dart';

/// Which half of a raw axis maps to a target axis.
enum AxisHalf {
  /// Full range of the raw axis maps to the target.
  full,

  /// Only the positive half (0 to max) maps to the target.
  positive,

  /// Only the negative half (min to 0) maps to the target.
  negative,
}

/// Describes how a raw axis maps to a normalized [GamepadAxis],
/// including half-axis and inversion modifiers.
class AxisMapping {
  final GamepadAxis axis;
  final AxisHalf half;
  final bool inverted;

  const AxisMapping(
    this.axis, {
    this.half = AxisHalf.full,
    this.inverted = false,
  });
}

/// A database entry describing how a specific controller maps its raw
/// key indices to standard gamepad buttons and axes.
class ControllerMapping {
  /// Maps raw button key strings to [GamepadButton].
  final Map<String, GamepadButton> buttons;

  /// Maps raw analog key strings to axis mappings.
  ///
  /// Each key can map to multiple axes (e.g., a combined trigger
  /// axis where positive half = left trigger and negative half =
  /// right trigger).
  final Map<String, List<AxisMapping>> axes;

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

/// Database of controller mappings, keyed by
/// (vendorId, productId, platform).
///
/// On first access, the bundled SDL GameController DB is automatically
/// parsed and loaded. Additional mappings can be added at runtime via
/// [loadSdlMappings].
///
/// The bundled database is sourced from the community-maintained
/// [SDL_GameControllerDB](https://github.com/gabomdq/SDL_GameControllerDB)
/// project and includes Linux and Windows entries for over 1500
/// controllers.
class ControllerDatabase {
  ControllerDatabase._();

  static Map<(int, int, GamepadPlatform), ControllerMapping>? _mappings;

  static Map<(int, int, GamepadPlatform), ControllerMapping> get _database {
    if (_mappings == null) {
      _mappings = {};
      _mappings!.addAll(
        SdlMappingParser.parseToPlatformDatabase(
          gamecontrollerDbData,
        ),
      );
    }
    return _mappings!;
  }

  /// Looks up a controller mapping by vendor ID, product ID, and
  /// platform.
  ///
  /// On first call, the bundled SDL GameController DB is
  /// automatically parsed. Returns `null` if the controller is not
  /// in the database for the given platform.
  static ControllerMapping? lookup({
    required int vendorId,
    required int productId,
    required GamepadPlatform platform,
  }) {
    return _database[(vendorId, productId, platform)];
  }

  /// Loads additional controller mappings from an SDL GameController
  /// DB format string.
  ///
  /// Only entries matching [platform] are loaded.
  /// Loaded mappings are merged with (and can override) the bundled
  /// database.
  ///
  /// Returns the number of mappings loaded.
  static int loadSdlMappings(
    String content, {
    required GamepadPlatform platform,
  }) {
    final parsed = SdlMappingParser.parseToPlatformDatabase(
      content,
      platform: platform,
    );
    _database.addAll(parsed);
    return parsed.length;
  }

  /// Resets the database to its initial state. The bundled SDL
  /// database will be re-parsed on the next lookup.
  static void resetMappings() {
    _mappings = null;
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
      '0': [AxisMapping(GamepadAxis.leftStickX)],
      '1': [AxisMapping(GamepadAxis.leftStickY)],
      '2': [AxisMapping(GamepadAxis.leftTrigger)],
      '3': [AxisMapping(GamepadAxis.rightStickX)],
      '4': [AxisMapping(GamepadAxis.rightStickY)],
      '5': [AxisMapping(GamepadAxis.rightTrigger)],
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
