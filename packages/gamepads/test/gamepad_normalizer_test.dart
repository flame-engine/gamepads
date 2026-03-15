import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/api/normalized_gamepad_event.dart';
import 'package:gamepads/src/gamepad_normalizer.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';

void main() {
  group('GamepadNormalizer', () {
    group('iOS platform', () {
      final normalizer = GamepadNormalizer(platform: GamepadPlatform.ios);

      test('normalizes button event', () {
        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.button,
          key: 'buttonA',
          value: 1.0,
        );

        final results = normalizer.normalize(event);
        expect(results.length, 1);
        expect(results.first.button, GamepadButton.a);
        expect(results.first.axis, isNull);
        expect(results.first.value, 1.0);
        expect(results.first.gamepadId, 'pad1');
        expect(results.first.timestamp, 1000);
        expect(results.first.rawEvent, same(event));
      });

      test('normalizes analog stick event', () {
        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 2000,
          type: KeyType.analog,
          key: 'leftStick - xAxis',
          value: 0.75,
        );

        final results = normalizer.normalize(event);
        expect(results.length, 1);
        expect(results.first.axis, GamepadAxis.leftStickX);
        expect(results.first.button, isNull);
        expect(results.first.value, 0.75);
      });

      test('d-pad axis produces multiple button events', () {
        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 3000,
          type: KeyType.analog,
          key: 'dpad - xAxis',
          value: -1.0,
        );

        final results = normalizer.normalize(event);
        expect(results.length, 2);
        expect(results[0].button, GamepadButton.dpadLeft);
        expect(results[0].value, 1.0);
        expect(results[1].button, GamepadButton.dpadRight);
        expect(results[1].value, 0.0);
      });

      test('unknown key produces empty results', () {
        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 4000,
          type: KeyType.button,
          key: 'unknownKey',
          value: 1.0,
        );

        expect(normalizer.normalize(event), isEmpty);
      });
    });

    group('Android platform', () {
      final normalizer = GamepadNormalizer(platform: GamepadPlatform.android);

      test('normalizes Android button', () {
        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.button,
          key: 'KEYCODE_BUTTON_A',
          value: 1.0,
        );

        final results = normalizer.normalize(event);
        expect(results.length, 1);
        expect(results.first.button, GamepadButton.a);
      });

      test('normalizes Android axis with Y inversion', () {
        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.analog,
          key: 'AXIS_Y',
          value: 1.0,
        );

        final results = normalizer.normalize(event);
        expect(results.first.axis, GamepadAxis.leftStickY);
        expect(results.first.value, -1.0);
      });
    });

    group('Web platform', () {
      final normalizer = GamepadNormalizer(platform: GamepadPlatform.web);

      test('normalizes Web button', () {
        final event = GamepadEvent(
          gamepadId: '0',
          timestamp: 1000,
          type: KeyType.button,
          key: 'button 0',
          value: 1.0,
        );

        final results = normalizer.normalize(event);
        expect(results.first.button, GamepadButton.a);
      });

      test('normalizes Web axis', () {
        final event = GamepadEvent(
          gamepadId: '0',
          timestamp: 1000,
          type: KeyType.analog,
          key: 'analog 0',
          value: -0.5,
        );

        final results = normalizer.normalize(event);
        expect(results.first.axis, GamepadAxis.leftStickX);
        expect(results.first.value, -0.5);
      });
    });

    group('stream transformer', () {
      test('transforms stream of events', () async {
        final normalizer = GamepadNormalizer(platform: GamepadPlatform.ios);

        final events = [
          GamepadEvent(
            gamepadId: 'pad1',
            timestamp: 1000,
            type: KeyType.button,
            key: 'buttonA',
            value: 1.0,
          ),
          GamepadEvent(
            gamepadId: 'pad1',
            timestamp: 2000,
            type: KeyType.analog,
            key: 'leftStick - xAxis',
            value: 0.5,
          ),
          GamepadEvent(
            gamepadId: 'pad1',
            timestamp: 3000,
            type: KeyType.button,
            key: 'unknownKey',
            value: 1.0,
          ),
        ];

        final stream = Stream.fromIterable(events);
        final normalized = await stream
            .transform(normalizer.transformer)
            .toList();

        // The unknown key event should be dropped
        expect(normalized.length, 2);
        expect(normalized[0].button, GamepadButton.a);
        expect(normalized[1].axis, GamepadAxis.leftStickX);
      });
    });

    group('device-specific mappings', () {
      test('setDeviceInfo selects controller-specific mapping', () {
        final normalizer = GamepadNormalizer(platform: GamepadPlatform.linux);
        normalizer.setDeviceInfo(
          'pad1',
          vendorId: 0x045e,
          productId: 0x028e,
        );

        final event = GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.button,
          key: '0',
          value: 1.0,
        );

        final results = normalizer.normalize(event);
        expect(results.first.button, GamepadButton.a);
      });
    });
  });

  group('NormalizedGamepadEvent', () {
    test('toString for button event', () {
      final event = NormalizedGamepadEvent(
        gamepadId: 'pad1',
        timestamp: 1000,
        button: GamepadButton.a,
        value: 1.0,
        rawEvent: GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.button,
          key: 'buttonA',
          value: 1.0,
        ),
      );

      expect(event.toString(), contains('button'));
      expect(event.toString(), contains('pad1'));
    });

    test('toString for axis event', () {
      final event = NormalizedGamepadEvent(
        gamepadId: 'pad1',
        timestamp: 1000,
        axis: GamepadAxis.leftStickX,
        value: 0.5,
        rawEvent: GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.analog,
          key: 'leftStick - xAxis',
          value: 0.5,
        ),
      );

      expect(event.toString(), contains('axis'));
    });
  });
}
