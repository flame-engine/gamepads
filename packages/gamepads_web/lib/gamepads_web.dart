// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

import 'package:gamepads_web/gamepad_detector.dart';
import 'package:web/web.dart' as web;

class GamePadState {
  GamePadState(int length) {
    keyStates = List<dynamic>.filled(length, null);
    axesStates = List<dynamic>.filled(4, null);
  }

  List<dynamic>? keyStates;
  List<dynamic>? axesStates;
}

/// A web implementation of the GamepadsWebPlatform of the GamepadsWeb plugin.
class GamepadsWeb extends GamepadsPlatformInterface {
  int _gamepadCount = 0;
  Timer? _gamepadPollingTimer;

  Map<String, GamePadState> lastGamePadstates = {};

  void updateGamepadsStatus() {
    final gamepads = getGamepadList();
    for (int i = 0; i < gamepads.length; i++) {
      final gamepad = gamepads[i];
      if (gamepad != null) {
        final int buttoncount = gamepad.buttons.length;
        final String gamepadId = gamepad.index.toString();
        GamePadState lastState;
        if (lastGamePadstates.containsKey(gamepadId) &&
            lastGamePadstates[gamepadId]?.keyStates?.length == buttoncount) {
          lastState = lastGamePadstates[gamepadId]!;
        } else {
          lastGamePadstates[gamepadId] = GamePadState(buttoncount);
          lastState = lastGamePadstates[gamepadId]!;
        }
        for (int i = 0; i < buttoncount; i++) {
          if (lastState.keyStates?[i] != gamepad.buttons[i].value) {
            lastState.keyStates?[i] = gamepad.buttons[i].value;
            emitGamepadEvent(
              GamepadEvent(
                gamepadId: gamepadId,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                type: KeyType.button,
                key: 'button $i',
                value: gamepad.buttons[i].value,
              ),
            );
          }
        }
        for (int i = 0; i < 4; i++) {
          if (lastState.keyStates?[i] != gamepad.axes[i]) {
            if (gamepad.axes[i] > 0.1 || gamepad.axes[i] < -0.1) {
              lastState.axesStates?[i] = gamepad.axes[i];
              emitGamepadEvent(
                GamepadEvent(
                  gamepadId: gamepadId,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  type: KeyType.analog,
                  key: 'analog $i',
                  value: gamepad.axes[i],
                ),
              );
            }
          }
        }
      }
    }
  }

  /// Constructs a GamepadsWeb
  GamepadsWeb() {
    web.window.addEventListener(
      'gamepadconnected',
      (web.Event event) {
        _gamepadCount++;
        if (_gamepadCount == 1) {
          // The game pad state for web is not event driven. We need to
          // query the game pad state by ourself.
          // By default we set the query interval is 1ms.
          _gamepadPollingTimer =
              Timer.periodic(const Duration(milliseconds: 1), (timer) {
            updateGamepadsStatus();
          });
        }
      }.toJS,
    );

    web.window.addEventListener(
      'gamepaddisconnected',
      (web.Event event) {
        _gamepadCount--;
        if (_gamepadCount == 0) {
          _gamepadPollingTimer?.cancel();
        }
      }.toJS,
    );
  }

  static void registerWith(Registrar registrar) {
    GamepadsPlatformInterface.instance = GamepadsWeb();
  }

  List<GamepadController>? controllers;

  @override
  Future<List<GamepadController>> listGamepads() async {
    controllers = getGamepads(this);
    return controllers!;
  }

  void emitGamepadEvent(GamepadEvent event) {
    _gamepadEventsStreamController.add(event);
  }

  final StreamController<GamepadEvent> _gamepadEventsStreamController =
      StreamController<GamepadEvent>.broadcast();

  @override
  Stream<GamepadEvent> get gamepadEventsStream =>
      _gamepadEventsStreamController.stream;

  @mustCallSuper
  Future<void> dispose() async {
    _gamepadEventsStreamController.close();
  }
}
