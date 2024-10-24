import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_web/gamepad_detector.dart';
import 'package:web/web.dart' as web;

class _GamePadState {
  _GamePadState(int length) {
    keyStates = List<dynamic>.filled(length, null);
    axesStates = List<double>.filled(4, 0);
  }

  List<dynamic>? keyStates;
  List<double>? axesStates;
}

/// A web implementation of the GamepadsWebPlatform of the GamepadsWeb plugin.
class GamepadsWeb extends GamepadsPlatformInterface {
  int _gamepadCount = 0;
  Timer? _gamepadPollingTimer;

  final Map<String, _GamePadState> _lastGamePadstates = {};

  void updateGamepadsStatus() {
    final gamepads = getGamepadList();
    for (final gamepad in gamepads) {
      final buttonlist = gamepad!.buttons.toDart;
      final axeslist = gamepad.axes.toDart;
      final gamepadId = gamepad.index.toString();
      _GamePadState lastState;
      if (_lastGamePadstates.containsKey(gamepadId) &&
          _lastGamePadstates[gamepadId]?.keyStates?.length ==
              buttonlist.length) {
        lastState = _lastGamePadstates[gamepadId]!;
      } else {
        _lastGamePadstates[gamepadId] = _GamePadState(buttonlist.length);
        lastState = _lastGamePadstates[gamepadId]!;
      }
      for (var i = 0; i < buttonlist.length; i++) {
        if (lastState.keyStates?[i] != buttonlist[i].value) {
          lastState.keyStates?[i] = buttonlist[i].value;
          emitGamepadEvent(
            GamepadEvent(
              gamepadId: gamepadId,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              type: KeyType.button,
              key: 'button $i',
              value: buttonlist[i].value,
            ),
          );
        }
      }
      for (var i = 0; i < 4; i++) {
        if ((lastState.axesStates![i] - axeslist[i].toDartDouble).abs() >
            0.03) {
          lastState.axesStates?[i] = axeslist[i].toDartDouble;
          emitGamepadEvent(
            GamepadEvent(
              gamepadId: gamepadId,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              type: KeyType.analog,
              key: 'analog $i',
              value: axeslist[i].toDartDouble,
            ),
          );
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
