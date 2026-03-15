import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/api/normalized_gamepad_event.dart';

/// The current normalized state of a gamepad.
///
/// This class keeps mutable state and is intended to be kept up-to-date by
/// calling [update] with the latest [NormalizedGamepadEvent].
class NormalizedGamepadState {
  /// Current state of all axes, keyed by [GamepadAxis].
  final Map<GamepadAxis, double> axes = {};

  /// Current state of all buttons, keyed by [GamepadButton].
  final Map<GamepadButton, bool> buttons = {};

  /// Updates the state based on the given normalized event.
  void update(NormalizedGamepadEvent event) {
    if (event.button != null) {
      buttons[event.button!] = event.value != 0;
    }
    if (event.axis != null) {
      axes[event.axis!] = event.value;
    }
  }

  /// Returns the current value of the given axis, or 0.0 if not yet received.
  double axisValue(GamepadAxis axis) => axes[axis] ?? 0.0;

  /// Returns whether the given button is currently pressed.
  bool isPressed(GamepadButton button) => buttons[button] ?? false;
}
