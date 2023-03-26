library gamepads;

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

class Gamepad {
  static final _platform = GamepadsPlatformInterface.instance;

  Future<List<GamepadController>> listGamepads() => _platform.listGamepads();

  Stream<GamepadEvent> get gamepadEventsStream => _platform.gamepadEventsStream;
}
