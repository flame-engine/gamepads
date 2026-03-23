import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/mappings/android_mapping.dart';
import 'package:gamepads/src/mappings/ios_mapping.dart';
import 'package:gamepads/src/mappings/linux_mapping.dart';
import 'package:gamepads/src/mappings/macos_mapping.dart';
import 'package:gamepads/src/mappings/web_standard_mapping.dart';
import 'package:gamepads/src/mappings/windows_mapping.dart';

void main() {
  group('IosMapping', () {
    final mapping = IosMapping();

    test('normalizes face buttons', () {
      expect(
        mapping.normalizeButton('buttonA', 1.0)?.button,
        GamepadButton.a,
      );
      expect(
        mapping.normalizeButton('buttonB', 1.0)?.button,
        GamepadButton.b,
      );
      expect(
        mapping.normalizeButton('buttonX', 1.0)?.button,
        GamepadButton.x,
      );
      expect(
        mapping.normalizeButton('buttonY', 1.0)?.button,
        GamepadButton.y,
      );
    });

    test('normalizes shoulder buttons', () {
      expect(
        mapping.normalizeButton('leftShoulder', 1.0)?.button,
        GamepadButton.leftBumper,
      );
      expect(
        mapping.normalizeButton('rightShoulder', 1.0)?.button,
        GamepadButton.rightBumper,
      );
    });

    test('normalizes trigger buttons', () {
      expect(
        mapping.normalizeButton('leftTrigger', 1.0)?.button,
        GamepadButton.leftTrigger,
      );
      expect(
        mapping.normalizeButton('rightTrigger', 1.0)?.button,
        GamepadButton.rightTrigger,
      );
    });

    test('normalizes system buttons', () {
      expect(
        mapping.normalizeButton('buttonMenu', 1.0)?.button,
        GamepadButton.start,
      );
      expect(
        mapping.normalizeButton('buttonOptions', 1.0)?.button,
        GamepadButton.back,
      );
      expect(
        mapping.normalizeButton('buttonHome', 1.0)?.button,
        GamepadButton.home,
      );
    });

    test('normalizes thumbstick clicks', () {
      expect(
        mapping.normalizeButton('leftThumbstickButton', 1.0)?.button,
        GamepadButton.leftStick,
      );
      expect(
        mapping.normalizeButton('rightThumbstickButton', 1.0)?.button,
        GamepadButton.rightStick,
      );
    });

    test('normalizes button values', () {
      expect(mapping.normalizeButton('buttonA', 1.0)?.value, 1.0);
      expect(mapping.normalizeButton('buttonA', 0.0)?.value, 0.0);
      expect(mapping.normalizeButton('buttonA', 0.5)?.value, 1.0);
    });

    test('returns null for unknown buttons', () {
      expect(mapping.normalizeButton('unknownButton', 1.0), isNull);
    });

    test('normalizes stick axes', () {
      expect(
        mapping.normalizeAxis('leftStick - xAxis', 0.5).firstOrNull?.axis,
        GamepadAxis.leftStickX,
      );
      expect(
        mapping.normalizeAxis('leftStick - yAxis', -0.3).firstOrNull?.axis,
        GamepadAxis.leftStickY,
      );
      expect(
        mapping.normalizeAxis('rightStick - xAxis', 1.0).firstOrNull?.axis,
        GamepadAxis.rightStickX,
      );
      expect(
        mapping.normalizeAxis('rightStick - yAxis', -1.0).firstOrNull?.axis,
        GamepadAxis.rightStickY,
      );
    });

    test('preserves stick axis values', () {
      final leftX = mapping.normalizeAxis(
        'leftStick - xAxis',
        0.75,
      );
      expect(leftX.first.value, 0.75);
      final leftY = mapping.normalizeAxis(
        'leftStick - yAxis',
        -0.5,
      );
      expect(leftY.first.value, -0.5);
    });

    test('returns null for unknown axes', () {
      expect(mapping.normalizeAxis('unknown - xAxis', 0.5), isEmpty);
    });

    test('normalizes d-pad as buttons from axis events', () {
      final left = mapping.normalizeDpadAxis('dpad - xAxis', -1.0);
      expect(left.length, 2);
      expect(left[0].button, GamepadButton.dpadLeft);
      expect(left[0].value, 1.0);
      expect(left[1].button, GamepadButton.dpadRight);
      expect(left[1].value, 0.0);

      final up = mapping.normalizeDpadAxis('dpad - yAxis', 1.0);
      expect(up.length, 2);
      expect(up[0].button, GamepadButton.dpadDown);
      expect(up[0].value, 0.0);
      expect(up[1].button, GamepadButton.dpadUp);
      expect(up[1].value, 1.0);
    });
  });

  group('AndroidMapping', () {
    final mapping = AndroidMapping();

    test('normalizes face buttons', () {
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_A', 1.0)?.button,
        GamepadButton.a,
      );
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_B', 1.0)?.button,
        GamepadButton.b,
      );
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_X', 1.0)?.button,
        GamepadButton.x,
      );
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_Y', 1.0)?.button,
        GamepadButton.y,
      );
    });

    test('normalizes shoulder and trigger buttons', () {
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_L1', 1.0)?.button,
        GamepadButton.leftBumper,
      );
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_R1', 1.0)?.button,
        GamepadButton.rightBumper,
      );
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_L2', 1.0)?.button,
        GamepadButton.leftTrigger,
      );
      expect(
        mapping.normalizeButton('KEYCODE_BUTTON_R2', 1.0)?.button,
        GamepadButton.rightTrigger,
      );
    });

    test('normalizes d-pad buttons', () {
      expect(
        mapping.normalizeButton('KEYCODE_DPAD_UP', 1.0)?.button,
        GamepadButton.dpadUp,
      );
      expect(
        mapping.normalizeButton('KEYCODE_DPAD_DOWN', 1.0)?.button,
        GamepadButton.dpadDown,
      );
      expect(
        mapping.normalizeButton('KEYCODE_DPAD_LEFT', 1.0)?.button,
        GamepadButton.dpadLeft,
      );
      expect(
        mapping.normalizeButton('KEYCODE_DPAD_RIGHT', 1.0)?.button,
        GamepadButton.dpadRight,
      );
    });

    test('normalizes stick axes with Y inversion', () {
      final lx = mapping.normalizeAxis('AXIS_X', 0.5);
      expect(lx.first.axis, GamepadAxis.leftStickX);
      expect(lx.first.value, 0.5);

      // Y-axis should be inverted
      final ly = mapping.normalizeAxis('AXIS_Y', 0.5);
      expect(ly.first.axis, GamepadAxis.leftStickY);
      expect(ly.first.value, -0.5);

      final ry = mapping.normalizeAxis('AXIS_RZ', -1.0);
      expect(ry.first.axis, GamepadAxis.rightStickY);
      expect(ry.first.value, 1.0);
    });

    test('normalizes trigger axes', () {
      final lt = mapping.normalizeAxis('AXIS_LTRIGGER', 0.8);
      expect(lt.first.axis, GamepadAxis.leftTrigger);
      expect(lt.first.value, 0.8);

      final rt = mapping.normalizeAxis('AXIS_RTRIGGER', 1.0);
      expect(rt.first.axis, GamepadAxis.rightTrigger);
      expect(rt.first.value, 1.0);
    });

    test('normalizes alternate trigger axes', () {
      expect(
        mapping.normalizeAxis('AXIS_BRAKE', 0.5).firstOrNull?.axis,
        GamepadAxis.leftTrigger,
      );
      expect(
        mapping.normalizeAxis('AXIS_GAS', 0.5).firstOrNull?.axis,
        GamepadAxis.rightTrigger,
      );
    });

    test('normalizes hat d-pad axes', () {
      final right = mapping.normalizeDpadAxis('AXIS_HAT_X', 1.0);
      expect(right[0].button, GamepadButton.dpadLeft);
      expect(right[0].value, 0.0);
      expect(right[1].button, GamepadButton.dpadRight);
      expect(right[1].value, 1.0);

      // Android hat Y: positive = down
      final down = mapping.normalizeDpadAxis('AXIS_HAT_Y', 1.0);
      expect(down[0].button, GamepadButton.dpadDown);
      expect(down[0].value, 1.0);
      expect(down[1].button, GamepadButton.dpadUp);
      expect(down[1].value, 0.0);
    });
  });

  group('WebStandardMapping', () {
    final mapping = WebStandardMapping();

    test('normalizes all standard buttons', () {
      final expected = {
        'button 0': GamepadButton.a,
        'button 1': GamepadButton.b,
        'button 2': GamepadButton.x,
        'button 3': GamepadButton.y,
        'button 4': GamepadButton.leftBumper,
        'button 5': GamepadButton.rightBumper,
        'button 6': GamepadButton.leftTrigger,
        'button 7': GamepadButton.rightTrigger,
        'button 8': GamepadButton.back,
        'button 9': GamepadButton.start,
        'button 10': GamepadButton.leftStick,
        'button 11': GamepadButton.rightStick,
        'button 12': GamepadButton.dpadUp,
        'button 13': GamepadButton.dpadDown,
        'button 14': GamepadButton.dpadLeft,
        'button 15': GamepadButton.dpadRight,
        'button 16': GamepadButton.home,
      };

      for (final entry in expected.entries) {
        expect(
          mapping.normalizeButton(entry.key, 1.0)?.button,
          entry.value,
          reason: 'Expected ${entry.key} to map to ${entry.value}',
        );
      }
    });

    test('normalizes stick axes with Y inversion', () {
      expect(
        mapping.normalizeAxis('analog 0', 0.5).firstOrNull?.axis,
        GamepadAxis.leftStickX,
      );
      expect(mapping.normalizeAxis('analog 0', 0.5).firstOrNull?.value, 0.5);

      // Y-axis inverted
      expect(mapping.normalizeAxis('analog 1', 0.5).firstOrNull?.value, -0.5);
      expect(mapping.normalizeAxis('analog 3', -1.0).firstOrNull?.value, 1.0);
    });

    test('returns null for unknown keys', () {
      expect(mapping.normalizeButton('button 99', 1.0), isNull);
      expect(mapping.normalizeAxis('analog 99', 0.5), isEmpty);
    });
  });

  group('MacosMapping', () {
    final mapping = MacosMapping();

    test('normalizes Xbox-style face buttons', () {
      expect(
        mapping.normalizeButton('a.circle', 1.0)?.button,
        GamepadButton.a,
      );
      expect(
        mapping.normalizeButton('b.circle', 1.0)?.button,
        GamepadButton.b,
      );
      expect(
        mapping.normalizeButton('x.circle', 1.0)?.button,
        GamepadButton.x,
      );
      expect(
        mapping.normalizeButton('y.circle', 1.0)?.button,
        GamepadButton.y,
      );
    });

    test('normalizes DualSense PlayStation-style face buttons', () {
      expect(
        mapping.normalizeButton('xmark.circle', 1.0)?.button,
        GamepadButton.a,
      );
      expect(
        mapping.normalizeButton('circle.circle', 1.0)?.button,
        GamepadButton.b,
      );
      expect(
        mapping.normalizeButton('square.circle', 1.0)?.button,
        GamepadButton.x,
      );
      expect(
        mapping.normalizeButton('triangle.circle', 1.0)?.button,
        GamepadButton.y,
      );
    });

    test('normalizes back/select buttons', () {
      expect(
        mapping.normalizeButton('capsule.portrait', 1.0)?.button,
        GamepadButton.back,
      );
      expect(
        mapping.normalizeButton('minus.circle', 1.0)?.button,
        GamepadButton.back,
      );
      expect(
        mapping
            .normalizeButton(
              'rectangle.fill.on.rectangle.fill.circle',
              1.0,
            )
            ?.button,
        GamepadButton.back,
      );
      expect(
        mapping.normalizeButton('square.and.arrow.up', 1.0)?.button,
        GamepadButton.back,
      );
    });

    test('normalizes start/menu buttons', () {
      expect(
        mapping.normalizeButton('line.3.horizontal.circle', 1.0)?.button,
        GamepadButton.start,
      );
      expect(
        mapping.normalizeButton('plus.circle', 1.0)?.button,
        GamepadButton.start,
      );
    });

    test('normalizes shoulder buttons', () {
      expect(
        mapping.normalizeButton('l1.rectangle.roundedbottom', 1.0)?.button,
        GamepadButton.leftBumper,
      );
      expect(
        mapping.normalizeButton('r1.rectangle.roundedbottom', 1.0)?.button,
        GamepadButton.rightBumper,
      );
      expect(
        mapping.normalizeButton('l.rectangle.roundedbottom', 1.0)?.button,
        GamepadButton.leftBumper,
      );
      expect(
        mapping.normalizeButton('r.rectangle.roundedbottom', 1.0)?.button,
        GamepadButton.rightBumper,
      );
    });

    test('normalizes trigger buttons', () {
      expect(
        mapping.normalizeButton('zl.rectangle.roundedtop', 1.0)?.button,
        GamepadButton.leftTrigger,
      );
      expect(
        mapping.normalizeButton('zr.rectangle.roundedtop', 1.0)?.button,
        GamepadButton.rightTrigger,
      );
    });

    test('normalizes stick click variants', () {
      expect(
        mapping.normalizeButton('l.joystick.down', 1.0)?.button,
        GamepadButton.leftStick,
      );
      expect(
        mapping.normalizeButton('r.joystick.down', 1.0)?.button,
        GamepadButton.rightStick,
      );
    });

    test('normalizes stick axes', () {
      expect(
        mapping
            .normalizeAxis('l.joystick.tilt.up - xAxis', 0.5)
            .firstOrNull
            ?.axis,
        GamepadAxis.leftStickX,
      );
      expect(
        mapping
            .normalizeAxis('l.joystick.tilt.up - yAxis', -0.3)
            .firstOrNull
            ?.axis,
        GamepadAxis.leftStickY,
      );
      expect(
        mapping
            .normalizeAxis('r.joystick.tilt.up - xAxis', 1.0)
            .firstOrNull
            ?.axis,
        GamepadAxis.rightStickX,
      );
    });

    test('normalizes d-pad axes', () {
      final results = mapping.normalizeDpadAxis('dpad.up.fill - xAxis', -1.0);
      expect(results.length, 2);
      expect(results[0].button, GamepadButton.dpadLeft);
      expect(results[0].value, 1.0);
    });

    test('returns null for unrecognized keys', () {
      expect(mapping.normalizeButton('totally.unknown', 1.0), isNull);
      expect(mapping.normalizeAxis('something.else - xAxis', 0.5), isEmpty);
    });
  });

  group('LinuxMapping', () {
    test('requires device ID', () {
      final mapping = LinuxMapping();
      expect(mapping.requiresDeviceId, isTrue);
    });

    test('best-effort mode uses default mapping for unknown controllers', () {
      final mapping = LinuxMapping().forDevice(
        vendorId: 0x9999,
        productId: 0x9999,
      );
      // Should still work with default Xbox-like mapping
      expect(
        mapping.normalizeButton('0', 1.0)?.button,
        GamepadButton.a,
      );
    });

    test('strict mode returns null for unknown controllers', () {
      final mapping = LinuxMapping(
        unknownBehavior: UnknownControllerBehavior.strict,
      ).forDevice(vendorId: 0x9999, productId: 0x9999);
      expect(mapping.normalizeButton('0', 1.0), isNull);
    });

    test('resolves known controller from bundled DB', () {
      // Xbox 360 is in the bundled SDL GameController DB
      final mapping = LinuxMapping().forDevice(
        vendorId: 0x045e,
        productId: 0x028e,
      );
      expect(
        mapping.normalizeButton('0', 1.0)?.button,
        GamepadButton.a,
      );
      expect(
        mapping.normalizeButton('1', 1.0)?.button,
        GamepadButton.b,
      );
    });

    test('normalizes stick axis values from raw range', () {
      // Uses default best-effort mapping (Xbox-like)
      final mapping = LinuxMapping().forDevice(
        vendorId: 0x9999,
        productId: 0x9999,
      );

      // Left stick X: -32768 to 32767 → -1.0 to 1.0
      final leftStickX = mapping.normalizeAxis('0', 0.0);
      expect(leftStickX.first.axis, GamepadAxis.leftStickX);
      // 0 in [-32768, 32767] → ~0.0
      expect(leftStickX.first.value, closeTo(0.0, 0.01));

      // Full right
      final leftStickXMax = mapping.normalizeAxis('0', 32767.0);
      expect(leftStickXMax.first.value, closeTo(1.0, 0.01));
    });

    test('normalizes d-pad axes', () {
      // Uses default best-effort mapping (Xbox-like)
      final mapping = LinuxMapping().forDevice(
        vendorId: 0x9999,
        productId: 0x9999,
      );
      final results = mapping.normalizeDpadAxis('6', -1.0);
      expect(results.length, 2);
      expect(results[0].button, GamepadButton.dpadLeft);
      expect(results[0].value, 1.0);
      expect(results[1].button, GamepadButton.dpadRight);
      expect(results[1].value, 0.0);
    });
  });

  group('WindowsMapping', () {
    test('normalizes buttons', () {
      final mapping = WindowsMapping();
      expect(
        mapping.normalizeButton('a', 1.0)?.button,
        GamepadButton.a,
      );
      expect(
        mapping.normalizeButton('b', 1.0)?.button,
        GamepadButton.b,
      );
    });

    test('normalizes axis values from -1.0 to 1.0 range', () {
      final mapping = WindowsMapping();

      // Center value → ~0.0
      final center = mapping.normalizeAxis('leftThumbstickX', 0.0);
      expect(center.first.axis, GamepadAxis.leftStickX);
      expect(center.first.value, closeTo(0.0, 0.01));

      // Full right
      final max = mapping.normalizeAxis('leftThumbstickX', 1.0);
      expect(max.first.value, closeTo(1.0, 0.01));
    });

    test('normalizes trigger axis', () {
      final mapping = WindowsMapping();

      final up = mapping.normalizeAxis('leftTrigger', 0.0);
      expect(up.first.axis, GamepadAxis.leftTrigger);
      expect(up.first.value, closeTo(0.0, 0.01));
    });

    test('normalizes d-pad', () {
      final mapping = WindowsMapping();
      expect(
        mapping.normalizeButton('dpadUp', 1.0)?.button,
        GamepadButton.dpadUp,
      );
      expect(
        mapping.normalizeButton('dpadRight', 1.0)?.button,
        GamepadButton.dpadRight,
      );
      expect(
        mapping.normalizeButton('dpadDown', 1.0)?.button,
        GamepadButton.dpadDown,
      );
      expect(
        mapping.normalizeButton('dpadLeft', 1.0)?.button,
        GamepadButton.dpadLeft,
      );
    });
  });
}
