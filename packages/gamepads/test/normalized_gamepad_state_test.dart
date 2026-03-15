import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/api/normalized_gamepad_event.dart';
import 'package:gamepads/src/api/normalized_gamepad_state.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';

void main() {
  group('NormalizedGamepadState', () {
    late NormalizedGamepadState state;

    setUp(() {
      state = NormalizedGamepadState();
    });

    GamepadEvent createRawEvent() => GamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          type: KeyType.button,
          key: 'test',
          value: 0.0,
        );

    test('tracks button presses', () {
      state.update(
        NormalizedGamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          button: GamepadButton.a,
          value: 1.0,
          rawEvent: createRawEvent(),
        ),
      );

      expect(state.isPressed(GamepadButton.a), isTrue);
      expect(state.isPressed(GamepadButton.b), isFalse);
    });

    test('tracks button releases', () {
      state.update(
        NormalizedGamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          button: GamepadButton.a,
          value: 1.0,
          rawEvent: createRawEvent(),
        ),
      );
      state.update(
        NormalizedGamepadEvent(
          gamepadId: 'pad1',
          timestamp: 2000,
          button: GamepadButton.a,
          value: 0.0,
          rawEvent: createRawEvent(),
        ),
      );

      expect(state.isPressed(GamepadButton.a), isFalse);
    });

    test('tracks axis values', () {
      state.update(
        NormalizedGamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          axis: GamepadAxis.leftStickX,
          value: 0.75,
          rawEvent: createRawEvent(),
        ),
      );

      expect(state.axisValue(GamepadAxis.leftStickX), 0.75);
      expect(state.axisValue(GamepadAxis.leftStickY), 0.0);
    });

    test('updates axis values', () {
      state.update(
        NormalizedGamepadEvent(
          gamepadId: 'pad1',
          timestamp: 1000,
          axis: GamepadAxis.leftStickX,
          value: 0.5,
          rawEvent: createRawEvent(),
        ),
      );
      state.update(
        NormalizedGamepadEvent(
          gamepadId: 'pad1',
          timestamp: 2000,
          axis: GamepadAxis.leftStickX,
          value: -0.3,
          rawEvent: createRawEvent(),
        ),
      );

      expect(state.axisValue(GamepadAxis.leftStickX), -0.3);
    });
  });
}
