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

class _GamepadState {
  _GamepadState(int amountOfKeys)
    : keyStates = List<double?>.filled(amountOfKeys, null),
      axesStates = List<double>.filled(4, 0);

  final List<double?> keyStates;
  final List<double> axesStates;
}

/// Parses vendor/product IDs from the Web Gamepad API id string.
///
/// Common formats:
/// - "Xbox 360 Controller (Vendor: 045e Product: 028e)"
/// - "045e-028e-Xbox 360 Controller"
({int? vendorId, int? productId}) _parseGamepadIds(String id) {
  // Try "Vendor: XXXX Product: XXXX" format
  final vendorMatch = RegExp(r'Vendor:\s*([0-9a-fA-F]{4})').firstMatch(id);
  final productMatch = RegExp(r'Product:\s*([0-9a-fA-F]{4})').firstMatch(id);
  if (vendorMatch != null && productMatch != null) {
    return (
      vendorId: int.parse(vendorMatch.group(1)!, radix: 16),
      productId: int.parse(productMatch.group(1)!, radix: 16),
    );
  }

  // Try "XXXX-XXXX-Name" format
  final dashMatch = RegExp(
    '^([0-9a-fA-F]{4})-([0-9a-fA-F]{4})',
  ).firstMatch(id);
  if (dashMatch != null) {
    return (
      vendorId: int.parse(dashMatch.group(1)!, radix: 16),
      productId: int.parse(dashMatch.group(2)!, radix: 16),
    );
  }

  return (vendorId: null, productId: null);
}

/// A web implementation of the GamepadsWebPlatform of the GamepadsWeb plugin.
class GamepadsWeb extends GamepadsPlatformInterface {
  int _gamepadCount = 0;
  Timer? _gamepadPollingTimer;

  final Map<String, _GamepadState> _lastGamepadStates = {};
  final Map<String, ({int? vendorId, int? productId})> _gamepadIds = {};

  void updateGamepadsStatus() {
    final gamepads = getGamepadList();
    for (final gamepad in gamepads) {
      final buttons = gamepad.buttons.toDart;
      final axes = gamepad.axes.toDart;
      final gamepadId = gamepad.index.toString();
      final ids = _gamepadIds.putIfAbsent(
        gamepadId,
        () => _parseGamepadIds(gamepad.id),
      );
      final _GamepadState lastState;
      if (_lastGamepadStates.containsKey(gamepadId) &&
          _lastGamepadStates[gamepadId]?.keyStates.length == buttons.length) {
        lastState = _lastGamepadStates[gamepadId]!;
      } else {
        _lastGamepadStates[gamepadId] = _GamepadState(buttons.length);
        lastState = _lastGamepadStates[gamepadId]!;
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
              vendorId: ids.vendorId,
              productId: ids.productId,
            ),
          );
        }
      }
      for (var i = 0; i < lastState.axesStates.length; i++) {
        if ((lastState.axesStates[i] - axes[i].toDartDouble).abs() > 0.03) {
          lastState.axesStates[i] = axes[i].toDartDouble;
          emitGamepadEvent(
            GamepadEvent(
              gamepadId: gamepadId,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              type: KeyType.analog,
              key: 'analog $i',
              value: axes[i].toDartDouble,
              vendorId: ids.vendorId,
              productId: ids.productId,
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
