import 'dart:js_interop';

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

@JS('navigator')
external Navigator get navigator;

@JS()
@staticInterop
class Navigator {}

@JS()
@staticInterop
class JSArray {}

@JS()
@staticInterop
class Gamepad {}

extension NavigatorGamepads on Navigator {
  external JSArray getGamepads();
}

// Extension for JSArray to handle array access
extension JSArrayInterop on JSArray {
  external int get length;
  external JSAny? operator [](int index);
}

// Extension for Gamepad to access its properties
extension GamepadInterop on Gamepad {
  external int get index;
  external String get id;
}

List<GamepadController> getGamepads(GamepadsPlatformInterface plugin) {
  final controllers = <GamepadController>[];
  final gamepads = navigator.getGamepads();

  for (var i = 0; i < gamepads.length; i++) {
    final gamepad = gamepads[i] as Gamepad?;
    if (gamepad != null) {
      controllers.add(
        GamepadController(
          id: gamepad.index.toString(),
          name: gamepad.id,
          plugin: plugin,
        ),
      );
    }
  }
  return controllers;
}

List<dynamic> getGamepadList() {
  final gamepads = navigator.getGamepads();
  return List.generate(gamepads.length, (i) {
    final gamepad = gamepads[i];
    if (gamepad != null) {
      return gamepad;
    }
    return null;
  }).where((gamepad) => gamepad != null).toList();
}
