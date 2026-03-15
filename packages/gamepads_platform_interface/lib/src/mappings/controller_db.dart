import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';

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

/// Database of known controller mappings, keyed by (vendorId, productId).
///
/// This will be expanded in Phase 4 with entries for Xbox, PlayStation,
/// Nintendo, and other common controllers.
class ControllerDb {
  ControllerDb._();

  /// Looks up a controller mapping by vendor and product ID.
  ///
  /// Returns `null` if the controller is not in the database.
  static ControllerMapping? lookup({
    required int vendorId,
    required int productId,
  }) {
    return _db[(vendorId, productId)];
  }

  // Xbox 360 Controller (common VID/PID).
  static const _xbox360 = ControllerMapping(
    buttons: {
      // Linux button indices for Xbox 360
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
      '6': true, // X axis
      '7': false, // Y axis
    },
    yAxisInverted: true,
    stickRange: (-32768, 32767),
    triggerRange: (-32768, 32767),
  );

  // Xbox One / Series Controller.
  static const _xboxOne = ControllerMapping(
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

  // DualShock 4 (PS4).
  static const _ds4 = ControllerMapping(
    buttons: {
      '0': GamepadButton.x,
      '1': GamepadButton.a,
      '2': GamepadButton.b,
      '3': GamepadButton.y,
      '4': GamepadButton.leftBumper,
      '5': GamepadButton.rightBumper,
      '6': GamepadButton.leftTrigger,
      '7': GamepadButton.rightTrigger,
      '8': GamepadButton.back,
      '9': GamepadButton.start,
      '10': GamepadButton.leftStick,
      '11': GamepadButton.rightStick,
      '12': GamepadButton.home,
    },
    axes: {
      '0': GamepadAxis.leftStickX,
      '1': GamepadAxis.leftStickY,
      '2': GamepadAxis.rightStickX,
      '3': GamepadAxis.leftTrigger,
      '4': GamepadAxis.rightTrigger,
      '5': GamepadAxis.rightStickY,
    },
    dpadAxes: {
      '6': true,
      '7': false,
    },
    yAxisInverted: true,
    stickRange: (-32768, 32767),
    triggerRange: (-32768, 32767),
  );

  // DualSense (PS5).
  static const _dualsense = ControllerMapping(
    buttons: {
      '0': GamepadButton.x,
      '1': GamepadButton.a,
      '2': GamepadButton.b,
      '3': GamepadButton.y,
      '4': GamepadButton.leftBumper,
      '5': GamepadButton.rightBumper,
      '6': GamepadButton.leftTrigger,
      '7': GamepadButton.rightTrigger,
      '8': GamepadButton.back,
      '9': GamepadButton.start,
      '10': GamepadButton.leftStick,
      '11': GamepadButton.rightStick,
      '12': GamepadButton.home,
    },
    axes: {
      '0': GamepadAxis.leftStickX,
      '1': GamepadAxis.leftStickY,
      '2': GamepadAxis.rightStickX,
      '3': GamepadAxis.leftTrigger,
      '4': GamepadAxis.rightTrigger,
      '5': GamepadAxis.rightStickY,
    },
    dpadAxes: {
      '6': true,
      '7': false,
    },
    yAxisInverted: true,
    stickRange: (-32768, 32767),
    triggerRange: (-32768, 32767),
  );

  // Nintendo Switch Pro Controller.
  static const _switchPro = ControllerMapping(
    buttons: {
      '0': GamepadButton.b,
      '1': GamepadButton.a,
      '2': GamepadButton.y,
      '3': GamepadButton.x,
      '4': GamepadButton.leftBumper,
      '5': GamepadButton.rightBumper,
      '6': GamepadButton.leftTrigger,
      '7': GamepadButton.rightTrigger,
      '8': GamepadButton.back,
      '9': GamepadButton.start,
      '10': GamepadButton.leftStick,
      '11': GamepadButton.rightStick,
      '12': GamepadButton.home,
    },
    axes: {
      '0': GamepadAxis.leftStickX,
      '1': GamepadAxis.leftStickY,
      '2': GamepadAxis.rightStickX,
      '3': GamepadAxis.rightStickY,
    },
    dpadAxes: {
      '4': true,
      '5': false,
    },
    yAxisInverted: true,
    stickRange: (-32768, 32767),
  );

  /// Default Xbox-like mapping used as a best-effort fallback for unknown
  /// controllers.
  static const defaultMapping = _xbox360;

  static const _db = <(int, int), ControllerMapping>{
    // Xbox 360 Controller
    (0x045e, 0x028e): _xbox360,
    // Xbox 360 Wireless Receiver
    (0x045e, 0x0719): _xbox360,
    // Xbox One Controller
    (0x045e, 0x02d1): _xboxOne,
    // Xbox One S Controller
    (0x045e, 0x02ea): _xboxOne,
    // Xbox Series X|S Controller
    (0x045e, 0x0b12): _xboxOne,
    // Xbox Series X|S Controller (Bluetooth)
    (0x045e, 0x0b13): _xboxOne,
    // DualShock 4 (v1)
    (0x054c, 0x05c4): _ds4,
    // DualShock 4 (v2)
    (0x054c, 0x09cc): _ds4,
    // DualSense (PS5)
    (0x054c, 0x0ce6): _dualsense,
    // DualSense Edge
    (0x054c, 0x0df2): _dualsense,
    // Nintendo Switch Pro Controller
    (0x057e, 0x2009): _switchPro,
  };
}
