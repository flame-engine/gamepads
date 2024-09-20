import 'package:gamepads_platform_interface/api/gamepad_event.dart';

class GamepadState {
  final Map<String, double> analogInputs = {};
  final Map<String, bool> buttonInputs = {};

  void update(GamepadEvent event) {
    switch (event.type) {
      case KeyType.analog:
        analogInputs[event.key] = event.value;
        break;
      case KeyType.button:
        buttonInputs[event.key] = event.value == 1;
        break;
    }
  }
}
