import 'package:gamepads_platform_interface/api/gamepad_event.dart';

/// The current state of a gamepad.
///
/// This class keeps mutable state and is intended to be kept up-to-date by
/// calling [update] with the latest [GamepadEvent]. The [analogInputs] and
/// [buttonInputs] maps correspond to [KeyType.analog] and [KeyType.button],
/// respectively.
class GamepadState {
  /// Contains inputs from events where [GamepadEvent.type] is [KeyType.analog].
  final Map<String, double> analogInputs = {};

  /// Contains inputs from events where [GamepadEvent.type] is [KeyType.button].
  final Map<String, bool> buttonInputs = {};

  /// Updates the state based on the given event.
  void update(GamepadEvent event) {
    switch (event.type) {
      case KeyType.analog:
        analogInputs[event.key] = event.value;
      case KeyType.button:
        buttonInputs[event.key] = event.value != 0;
    }
  }
}
