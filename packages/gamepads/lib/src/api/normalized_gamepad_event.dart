import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';

/// A gamepad event with platform-independent button/axis identifiers and
/// normalized values.
///
/// Either [button] or [axis] will be non-null, but not both.
///
/// Value conventions:
/// - Stick axes: -1.0 to 1.0 (Left/Down = -1, Right/Up = +1)
/// - Triggers: 0.0 to 1.0 (Released = 0, Fully pressed = 1)
/// - Buttons: 0.0 or 1.0 (Released = 0, Pressed = 1)
class NormalizedGamepadEvent {
  /// The id of the gamepad controller that fired the event.
  final String gamepadId;

  /// The timestamp in which the event was fired, in milliseconds since epoch.
  final int timestamp;

  /// The normalized button, if this is a button event.
  final GamepadButton? button;

  /// The normalized axis, if this is an axis event.
  final GamepadAxis? axis;

  /// The normalized value.
  final double value;

  /// The original platform-specific event.
  final GamepadEvent rawEvent;

  NormalizedGamepadEvent({
    required this.gamepadId,
    required this.timestamp,
    required this.value,
    required this.rawEvent,
    this.button,
    this.axis,
  }) : assert(
         (button != null) ^ (axis != null),
         'Exactly one of button or axis must be non-null',
       );

  @override
  String toString() {
    final input = button != null ? 'button:$button' : 'axis:$axis';
    return '[$gamepadId] $input = $value';
  }
}
