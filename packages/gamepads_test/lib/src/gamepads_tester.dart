import 'package:gamepads/gamepads.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';

class GamepadsTester {
  static MethodChannelGamepadsPlatformInterface platformInterface =
      GamepadsPlatformInterface.instance
          as MethodChannelGamepadsPlatformInterface;

  /// Call this before calling any other method on GamepadsTester.
  ///
  /// As a side effect, sets Gamepads.normalizer to GamepadNormalizer
  /// for Windows platform.
  ///
  /// If you change Gamepads.normalizer, the emitted GamepadsTester
  /// events won't be normalized correctly by the Gamepads library.
  static void ensureInitialized() {
    Gamepads.normalizer = GamepadNormalizer.forPlatform(
      GamepadPlatform.windows,
    );
  }

  /// Emit a raw (non-normalized) button [rawButton] event with given [value]
  static void emitRawButton(String rawButton, double value) {
    _emitRaw(rawButton, KeyType.button, value);
  }

  /// Emit a raw (non-normalized) analog [rawAnalog] event with given [value]
  static void emitRawAnalog(String rawAnalog, double value) {
    _emitRaw(rawAnalog, KeyType.analog, value);
  }

  /// Emit normalized [button] with given [value] as a raw non-normalized
  /// button gamepad event.
  ///
  /// Send [value] == 0.0 for button up and 1.0 for button down.
  static void emitButton(GamepadButton button, double value) {
    final rawButton = switch (button) {
      .a => 'a',
      .b => 'b',
      .x => 'x',
      .y => 'y',
      .back => 'back',
      .start => 'start',
      .home => throw Exception(
        'Home button not supported by Windows gamepads platform',
      ),
      .dpadUp => 'dpadUp',
      .dpadDown => 'dpadDown',
      .dpadLeft => 'dpadLeft',
      .dpadRight => 'dpadRight',
      .leftBumper => 'leftShoulder',
      .rightBumper => 'rightShoulder',
      .leftStick => 'leftThumbstick',
      .rightStick => 'rightThumbstick',
      .touchpad => throw Exception(
        'Home button not supported by Windows gamepads platform',
      ),
      .leftTrigger => throw Exception('Emit leftTrigger as an axis value'),
      .rightTrigger => throw Exception('Emit rightTrigger as an axis value'),
    };
    emitRawButton(rawButton, value);
  }

  /// Emit normalized [axis] gamepad event with given [value] as a raw
  /// non-normalized analog gamepad event.
  static void emitAxis(GamepadAxis axis, double value) {
    final rawAnalog = switch (axis) {
      .leftStickX => 'leftThumbstickX',
      .leftStickY => 'leftThumbstickY',
      .rightStickX => 'rightThumbstickX',
      .rightStickY => 'rightThumbstickY',
      .leftTrigger => 'leftTrigger',
      .rightTrigger => 'rightTrigger',
    };
    emitRawAnalog(rawAnalog, value);
  }

  /// Emit a sequence of button down and button up events.
  static void emitButtonPress(GamepadButton button) {
    emitButton(button, 1.0);
    emitButton(button, 0.0);
  }

  static void _emitRaw(String rawKey, KeyType type, double value) {
    final millis = DateTime.now().millisecondsSinceEpoch;
    platformInterface.emitGamepadEvent(
      GamepadEvent(
        gamepadId: '1',
        timestamp: millis,
        type: type,
        key: rawKey,
        value: value,
      ),
    );
  }
}
