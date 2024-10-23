// gamepad_detector.dart
// ignore_for_file: omit_local_variable_types, avoid_dynamic_calls

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('navigator.getGamepads')
external dynamic _getGamepads();

List<GamepadController> getGamepads(GamepadsPlatformInterface plugin) {
  final controllers = <GamepadController>[];
  final gamepads = _getGamepads();
  for (int i = 0; i < gamepads.length; i++) {
    final gamepad = getProperty(gamepads, i.toString());
    if (gamepad != null) {
      controllers.add(
          GamepadController(id: gamepad.index.toString(),
                            name: gamepad.id,
                            plugin: plugin,),);
    }
  }
  return controllers;
}

List<dynamic> getGamepadList() {
  return _getGamepads();
}
