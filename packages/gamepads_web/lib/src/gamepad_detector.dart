import 'dart:js_interop';

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:web/web.dart';

List<GamepadController> getGamepads(GamepadsPlatformInterface plugin) {
  return getGamepadList()
    .map((gamepad) => GamepadController(
      id: gamepad.index.toString(),
      name: gamepad.id,
      plugin: plugin,
    ),)
    .toList();
}

List<Gamepad> getGamepadList() {
  return window.navigator.getGamepads()
    .toDart
    .whereType<Gamepad>()
    .toList();
}
