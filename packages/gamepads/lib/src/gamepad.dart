library gamepads;

import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

class Gamepad {
  static final _platform = GamepadsPlatformInterface.instance;

  Future<int> getValue() => _platform.getValue();
}
