import 'dart:async';
import 'dart:js_interop';

import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_web/src/gamepad_detector.dart' show getGamepadList;
import 'package:web/web.dart' as web;

extension type _Pad(JSObject _) implements JSObject {
  external _Actuator? get vibrationActuator;
}

extension type _Actuator(JSObject _) implements JSObject {
  external JSArray<JSString>? get effects;
  external JSString? get type;
  external JSPromise<JSString> playEffect(JSString type, JSObject parameters);
  external JSPromise<JSString> reset();
}

extension type _Parameters._(JSObject _) implements JSObject {
  external factory _Parameters({
    required int duration,
    required int startDelay,
    required double strongMagnitude,
    required double weakMagnitude,
  });
}

/// Browser effects may be limited to five seconds. Each replacement owns its
/// deadline and cancellation token, so old completions cannot restart a motor.
class GamepadRumble {
  final _active = <String, (_Actuator, Object)>{};

  _Actuator? _actuator(String id) {
    for (final pad in getGamepadList()) {
      if (pad.index.toString() == id && pad.connected) {
        return _Pad(pad).vibrationActuator;
      }
    }
    return null;
  }

  bool has(String id) {
    final actuator = _actuator(id);
    if (actuator == null) {
      return false;
    }
    final effects = actuator.effects;
    return effects == null
        ? actuator.type?.toDart == 'dual-rumble'
        : effects.toDart.any((effect) => effect.toDart == 'dual-rumble');
  }

  Future<bool> stop(String id) async {
    final actuator = _active.remove(id)?.$1 ?? _actuator(id);
    if (actuator == null) {
      return false;
    }
    try {
      await actuator.reset().toDart;
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> set(
    String id,
    double low,
    double high,
    Duration duration,
  ) async {
    GamepadsPlatformInterface.validateRumble(low, high, duration);
    if (duration.inMilliseconds == 0 || (low == 0 && high == 0)) {
      return stop(id);
    }
    if (!has(id)) {
      return false;
    }
    if (web.document.hidden) {
      return false;
    }
    final actuator = _actuator(id);
    if (actuator == null) {
      return false;
    }
    final token = Object();
    _active[id] = (actuator, token);
    final watch = Stopwatch()..start();
    final deadline = duration.inMilliseconds;
    Future<void> play() async {
      try {
        while (_active[id]?.$2 == token && !web.document.hidden) {
          final remaining = deadline - watch.elapsedMilliseconds;
          if (remaining <= 0 || _actuator(id) == null) {
            break;
          }
          final result = await actuator
              .playEffect(
                'dual-rumble'.toJS,
                _Parameters(
                  duration: remaining.clamp(1, 5000),
                  startDelay: 0,
                  strongMagnitude: low,
                  weakMagnitude: high,
                ),
              )
              .toDart;
          if (result.toDart != 'complete') {
            break;
          }
        }
      } on Object {
        // Unsupported effect, lost focus, permission denial or unplug.
      } finally {
        if (_active[id]?.$2 == token) {
          _active.remove(id);
          try {
            await actuator.reset().toDart;
          } on Object {
            /* disconnected */
          }
        }
      }
    }

    unawaited(play());
    return true;
  }

  void stopAll() {
    for (final id in _active.keys.toList()) {
      unawaited(stop(id));
    }
  }
}
