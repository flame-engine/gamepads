import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_web/src/gamepad_detector.dart'
    show getGamepadList, getGamepads;
import 'package:web/web.dart' as web;

class _GamePadState {
  _GamePadState(int amountOfKeys) :
    keyStates = List<double?>.filled(amountOfKeys, null),
    axesStates = List<double>.filled(4, 0);

  final List<double?> keyStates;
  final List<double> axesStates;
}

/// A web implementation of the GamepadsWebPlatform of the GamepadsWeb plugin.
class GamepadsWeb extends GamepadsPlatformInterface {
  int _gamepadCount = 0;
  Timer? _gamepadPollingTimer;

  final Map<String, _GamePadState> _lastGamePadStates = {};

  void updateGamepadsStatus() {
    final gamepads = getGamepadList();
    for (final gamepad in gamepads) {
      final buttons = gamepad.buttons.toDart;
      final axes = gamepad.axes.toDart;
      final gamepadId = gamepad.index.toString();
      final _GamePadState lastState;
      if (_lastGamePadStates.containsKey(gamepadId) &&
          _lastGamePadStates[gamepadId]?.keyStates.length ==
              buttons.length) {
        lastState = _lastGamePadStates[gamepadId]!;
      } else {
        _lastGamePadStates[gamepadId] = _GamePadState(buttons.length);
        lastState = _lastGamePadStates[gamepadId]!;
      }
      for (var i = 0; i < buttons.length; i++) {
        if (lastState.keyStates[i] != buttons[i].value) {
          lastState.keyStates[i] = buttons[i].value;
          emitGamepadEvent(
            GamepadEvent(
              gamepadId: gamepadId,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              type: KeyType.button,
              key: 'button $i',
              value: buttons[i].value,
            ),
          );
        }
      }
      for (var i = 0; i < lastState.axesStates.length; i++) {
        if ((lastState.axesStates[i] - axes[i].toDartDouble).abs() >
            0.03) {
          lastState.axesStates[i] = axes[i].toDartDouble;
          emitGamepadEvent(
            GamepadEvent(
              gamepadId: gamepadId,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              type: KeyType.analog,
              key: 'analog $i',
              value: axes[i].toDartDouble,
            ),
          );
        }
      }
    }
  }

  GamepadsWeb() {
    web.window.addEventListener(
      'gamepadconnected',
      (web.Event event) {
        _gamepadCount++;
        if (_gamepadCount == 1) {
          // The game pad state for web is not event driven. We need to
          // query the game pad state by ourself.
          // By default we set the query interval is 8 ms.
          _gamepadPollingTimer = Timer.periodic(
            const Duration(milliseconds: 8),
            (timer) {
              updateGamepadsStatus();
            },
          );
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
