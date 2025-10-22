import 'dart:js_interop';

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:web/web.dart';

List<GamepadController> getGamepads(GamepadsPlatformInterface plugin) {
  final controllers = <GamepadController>[];
  return getGamepadList()
    .map((gamepad) =>
      GamepadController(
        id: gamepad!.index.toString(),
        name: gamepad.id,
        plugin: plugin,
      ),
    );
}

List<Gamepad?> _getGamepadList() {
  final gamepads = window.navigator.getGamepads().toDart;
  gamepads.removeWhere((item) => item == null);
  return gamepads;
}
