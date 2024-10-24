import 'dart:js_interop';

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:web/web.dart';

List<GamepadController> getGamepads(GamepadsPlatformInterface plugin) {
  final controllers = <GamepadController>[];
  final gamepads = getGamepadList();
  for (var i = 0; i < gamepads.length; i++) {
    final gamepad = gamepads[i];
    controllers.add(
      GamepadController(
        id: gamepad!.index.toString(),
        name: gamepad.id,
        plugin: plugin,
      ),
    );
  }
  return controllers;
}

List<Gamepad?> getGamepadList() {
  final gamepads = window.navigator.getGamepads().toDart;
  gamepads.removeWhere((item) => item == null);
  return gamepads;
}
