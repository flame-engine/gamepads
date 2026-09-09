import 'package:gamepads/gamepads.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';

/// A class that can be used to emit gamepads events for your tests.
///
/// It emit non-normalized events which gamepads library may normalize
/// and provide also normalized events for the consumer.
///
/// It is therefore important that the button and axis names you emit
/// matches the one of the normalizer platform.
class GamepadsTester {
  static MethodChannelGamepadsPlatformInterface platformInterface =
      GamepadsPlatformInterface.instance
          as MethodChannelGamepadsPlatformInterface;

  /// Set Gamepads normalizer to a normalizer for [platform]
  ///
  /// Affects the names of buttons and analog axes you should emit for
  /// normalized events to be correctly mapped.
  static void setNormalizer(GamepadPlatform platform) {
    Gamepads.normalizer = GamepadNormalizer.forPlatform(platform);
  }

  /// Emit a raw (non-normalized) button [rawButton] event with given [value]
  static void emitRawButton(String rawButton, double value) {
    _emitRaw(rawButton, KeyType.button, value);
  }

  /// Emit a raw (non-normalized) analog [rawAnalog] event with given [value]
  static void emitRawAnalog(String rawAnalog, double value) {
    _emitRaw(rawAnalog, KeyType.analog, value);
  }

  /// Emit a sequence of raw (non-normalized) button down and button up events.
  static void emitRawButtonPress(String rawButton) {
    emitRawButton(rawButton, 1.0);
    emitRawButton(rawButton, 0.0);
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
