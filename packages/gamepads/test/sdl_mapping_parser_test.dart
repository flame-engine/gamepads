import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/src/api/gamepad_axis.dart';
import 'package:gamepads/src/api/gamepad_button.dart';
import 'package:gamepads/src/gamepad_normalizer.dart';
import 'package:gamepads/src/mappings/controller_database.dart';
import 'package:gamepads/src/mappings/sdl_mapping_parser.dart';

const _xboxGuid = '030000005e0400008e02000010010000';
const _sonyGuid = '030000004c050000cc09000011010000';
const _windowsGuid = '030000005e0400008e02000000000000';

/// Builds an SDL mapping line from a GUID and individual mapping fields.
String _sdlLine(String guid, List<String> fields) {
  return '$guid,${fields.join(',')}';
}

void main() {
  group('SdlMappingParser', () {
    group('GUID parsing', () {
      test('extracts vendor ID from GUID', () {
        // Bytes 4-5 (chars 8-11): "5e04" → LE → 0x045e
        expect(
          SdlMappingParser.extractVendorId(_xboxGuid),
          0x045e,
        );
      });

      test('extracts product ID from GUID', () {
        // Bytes 8-9 (chars 16-19): "8e02" → LE → 0x028e
        expect(
          SdlMappingParser.extractProductId(_xboxGuid),
          0x028e,
        );
      });

      test('extracts Sony VID/PID', () {
        expect(
          SdlMappingParser.extractVendorId(
            '030000004c050000cc09000000000000',
          ),
          0x054c,
        );
        expect(
          SdlMappingParser.extractProductId(
            '030000004c050000cc09000000000000',
          ),
          0x09cc,
        );
      });

      test('returns null for short GUIDs', () {
        expect(SdlMappingParser.extractVendorId('0300'), isNull);
        expect(
          SdlMappingParser.extractProductId('030000005e04'),
          isNull,
        );
      });
    });

    group('line parsing', () {
      test('parses Xbox 360 Linux mapping', () {
        final line = _sdlLine(_xboxGuid, [
          'Xbox 360 Controller',
          'a:b0',
          'b:b1',
          'x:b2',
          'y:b3',
          'back:b6',
          'start:b7',
          'guide:b8',
          'leftshoulder:b4',
          'rightshoulder:b5',
          'leftstick:b9',
          'rightstick:b10',
          'leftx:a0',
          'lefty:a1',
          'rightx:a3',
          'righty:a4',
          'lefttrigger:a2',
          'righttrigger:a5',
          'dpup:h0.1',
          'dpdown:h0.4',
          'dpleft:h0.8',
          'dpright:h0.2',
          'platform:Linux',
        ]);

        final result = SdlMappingParser.parseLine(line);
        expect(result, isNotNull);
        expect(result!.vendorId, 0x045e);
        expect(result.productId, 0x028e);
        expect(result.platform, GamepadPlatform.linux);

        final mapping = result.mapping;

        expect(mapping.buttons['0'], GamepadButton.a);
        expect(mapping.buttons['1'], GamepadButton.b);
        expect(mapping.buttons['2'], GamepadButton.x);
        expect(mapping.buttons['3'], GamepadButton.y);
        expect(mapping.buttons['4'], GamepadButton.leftBumper);
        expect(mapping.buttons['5'], GamepadButton.rightBumper);
        expect(mapping.buttons['6'], GamepadButton.back);
        expect(mapping.buttons['7'], GamepadButton.start);
        expect(mapping.buttons['8'], GamepadButton.home);
        expect(mapping.buttons['9'], GamepadButton.leftStick);
        expect(mapping.buttons['10'], GamepadButton.rightStick);

        expect(
          mapping.axes['0']?.first.axis,
          GamepadAxis.leftStickX,
        );
        expect(
          mapping.axes['1']?.first.axis,
          GamepadAxis.leftStickY,
        );
        expect(
          mapping.axes['2']?.first.axis,
          GamepadAxis.leftTrigger,
        );
        expect(
          mapping.axes['3']?.first.axis,
          GamepadAxis.rightStickX,
        );
        expect(
          mapping.axes['4']?.first.axis,
          GamepadAxis.rightStickY,
        );
        expect(
          mapping.axes['5']?.first.axis,
          GamepadAxis.rightTrigger,
        );

        // D-pad hat → axes (6 regular axes 0-5, hat 0 → 6,7)
        expect(mapping.dpadAxes['6'], isTrue);
        expect(mapping.dpadAxes['7'], isFalse);
      });

      test('parses DualShock 4 Linux mapping', () {
        final line = _sdlLine(_sonyGuid, [
          'Sony DualShock 4 V2',
          'a:b1',
          'b:b2',
          'x:b0',
          'y:b3',
          'back:b8',
          'start:b9',
          'guide:b12',
          'leftshoulder:b4',
          'rightshoulder:b5',
          'leftstick:b10',
          'rightstick:b11',
          'leftx:a0',
          'lefty:a1',
          'rightx:a2',
          'righty:a5',
          'lefttrigger:a3',
          'righttrigger:a4',
          'dpup:h0.1',
          'dpdown:h0.4',
          'dpleft:h0.8',
          'dpright:h0.2',
          'platform:Linux',
        ]);

        final result = SdlMappingParser.parseLine(line);
        expect(result, isNotNull);
        expect(result!.vendorId, 0x054c);
        expect(result.productId, 0x09cc);

        final mapping = result.mapping;
        expect(mapping.buttons['1'], GamepadButton.a);
        expect(mapping.buttons['2'], GamepadButton.b);
        expect(mapping.buttons['0'], GamepadButton.x);
        expect(mapping.buttons['3'], GamepadButton.y);
      });

      test('skips comment lines', () {
        expect(
          SdlMappingParser.parseLine('# This is a comment'),
          isNull,
        );
      });

      test('skips empty lines', () {
        expect(SdlMappingParser.parseLine(''), isNull);
        expect(SdlMappingParser.parseLine('   '), isNull);
      });

      test('skips malformed lines', () {
        expect(SdlMappingParser.parseLine('just,two'), isNull);
      });

      test('handles axis modifiers (inverted ~)', () {
        final line = _sdlLine(_xboxGuid, [
          'Test Controller',
          'leftx:a0~',
          'platform:Linux',
        ]);

        final result = SdlMappingParser.parseLine(line);
        expect(result, isNotNull);
        expect(
          result!.mapping.axes['0']?.first.axis,
          GamepadAxis.leftStickX,
        );
      });

      test('handles half-axis modifiers (+a, -a)', () {
        final line = _sdlLine(_xboxGuid, [
          'Test Controller',
          'lefttrigger:+a2',
          'righttrigger:-a2',
          'platform:Linux',
        ]);

        final result = SdlMappingParser.parseLine(line);
        expect(result, isNotNull);
        final axis2 = result!.mapping.axes['2']!;
        expect(axis2.length, 2);
        expect(axis2[0].axis, GamepadAxis.leftTrigger);
        expect(axis2[0].half, AxisHalf.positive);
        expect(axis2[1].axis, GamepadAxis.rightTrigger);
        expect(axis2[1].half, AxisHalf.negative);
      });
    });

    group('multi-line parsing', () {
      test('parses multiple lines with platform filter', () {
        final lines = [
          '# Test DB',
          _sdlLine(_xboxGuid, [
            'Xbox 360',
            'a:b0',
            'b:b1',
            'leftx:a0',
            'lefty:a1',
            'platform:Linux',
          ]),
          _sdlLine(_windowsGuid, [
            'Xbox 360',
            'a:b0',
            'b:b1',
            'leftx:a0',
            'lefty:a1',
            'platform:Windows',
          ]),
          _sdlLine(_sonyGuid, [
            'DS4',
            'a:b1',
            'b:b2',
            'leftx:a0',
            'lefty:a1',
            'platform:Linux',
          ]),
        ];
        final content = lines.join('\n');

        final linuxMappings = SdlMappingParser.parseLines(
          content,
          platform: GamepadPlatform.linux,
        );
        expect(linuxMappings.length, 2);

        final windowsMappings = SdlMappingParser.parseLines(
          content,
          platform: GamepadPlatform.windows,
        );
        expect(windowsMappings.length, 1);
      });

      test('parseToPlatformDatabase creates keyed map', () {
        final lines = [
          _sdlLine(_xboxGuid, [
            'Xbox 360',
            'a:b0',
            'b:b1',
            'leftx:a0',
            'lefty:a1',
            'platform:Linux',
          ]),
          _sdlLine(_sonyGuid, [
            'DS4',
            'a:b1',
            'b:b2',
            'leftx:a0',
            'lefty:a1',
            'platform:Linux',
          ]),
        ];
        final content = lines.join('\n');

        final database = SdlMappingParser.parseToPlatformDatabase(
          content,
          platform: GamepadPlatform.linux,
        );
        expect(database.length, 2);
        const xboxKey = (0x045e, 0x028e, GamepadPlatform.linux);
        const sonyKey = (0x054c, 0x09cc, GamepadPlatform.linux);
        expect(database[xboxKey], isNotNull);
        expect(database[sonyKey], isNotNull);
      });
    });

    group('ControllerDatabase SDL integration', () {
      tearDown(ControllerDatabase.resetMappings);

      test('loadSdlMappings adds to database', () {
        final content = _sdlLine(_xboxGuid, [
          'Custom Controller',
          'a:b0',
          'b:b1',
          'x:b2',
          'y:b3',
          'leftx:a0',
          'lefty:a1',
          'platform:Linux',
        ]);

        final count = ControllerDatabase.loadSdlMappings(
          content,
          platform: GamepadPlatform.linux,
        );
        expect(count, greaterThanOrEqualTo(0));
      });

      test('SDL-loaded mappings override bundled', () {
        final overrideContent = _sdlLine(_xboxGuid, [
          'Xbox 360 Override',
          'a:b1',
          'b:b0',
          'x:b2',
          'y:b3',
          'leftx:a0',
          'lefty:a1',
          'rightx:a3',
          'righty:a4',
          'lefttrigger:a2',
          'righttrigger:a5',
          'dpup:h0.1',
          'dpdown:h0.4',
          'dpleft:h0.8',
          'dpright:h0.2',
          'platform:Linux',
        ]);

        ControllerDatabase.loadSdlMappings(
          overrideContent,
          platform: GamepadPlatform.linux,
        );

        final mapping = ControllerDatabase.lookup(
          vendorId: 0x045e,
          productId: 0x028e,
          platform: GamepadPlatform.linux,
        );
        expect(mapping, isNotNull);
        expect(mapping!.buttons['1'], GamepadButton.a);
        expect(mapping.buttons['0'], GamepadButton.b);
      });

      test('resetMappings restores bundled DB', () {
        final overrideContent = _sdlLine(_xboxGuid, [
          'Xbox 360 Override',
          'a:b1',
          'b:b0',
          'leftx:a0',
          'lefty:a1',
          'platform:Linux',
        ]);

        ControllerDatabase.loadSdlMappings(
          overrideContent,
          platform: GamepadPlatform.linux,
        );
        ControllerDatabase.resetMappings();

        // After reset, bundled DB is re-loaded on next access.
        final mapping = ControllerDatabase.lookup(
          vendorId: 0x045e,
          productId: 0x028e,
          platform: GamepadPlatform.linux,
        );
        expect(mapping, isNotNull);
        expect(mapping!.buttons['0'], GamepadButton.a);
      });
    });
  });
}
