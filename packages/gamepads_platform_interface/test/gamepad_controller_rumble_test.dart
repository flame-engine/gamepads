import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

class _RecordingPlatform extends GamepadsPlatformInterface {
  final calls = <Object>[];

  @override
  Future<List<GamepadController>> listGamepads() async => [];

  @override
  Future<bool> hasRumble(String gamepadId) async {
    calls.add(('hasRumble', gamepadId));
    return true;
  }

  @override
  Future<bool> rumble(
    String gamepadId, {
    double lowFrequency = 0,
    double highFrequency = 0,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    calls.add(('rumble', gamepadId, lowFrequency, highFrequency, duration));
    return true;
  }

  @override
  Future<bool> stopRumble(String gamepadId) async {
    calls.add(('stopRumble', gamepadId));
    return true;
  }
}

void main() {
  test(
    'instance methods use the controller identity and its own backend',
    () async {
      final first = _RecordingPlatform();
      final second = _RecordingPlatform();
      final a = GamepadController(id: 'a', name: 'A', plugin: first);
      final b = GamepadController(id: 'b', name: 'B', plugin: second);
      addTearDown(() async {
        await a.dispose();
        await b.dispose();
        await first.dispose();
        await second.dispose();
      });
      expect(await a.hasRumble(), isTrue);
      expect(
        await a.rumble(
          lowFrequency: 0.25,
          highFrequency: 1,
          duration: const Duration(seconds: 2),
        ),
        isTrue,
      );
      expect(await b.stopRumble(), isTrue);
      expect(first.calls, [
        ('hasRumble', 'a'),
        ('rumble', 'a', 0.25, 1.0, const Duration(seconds: 2)),
      ]);
      expect(second.calls, [('stopRumble', 'b')]);
    },
  );

  test('instance validates rumble before calling the backend', () async {
    final platform = _RecordingPlatform();
    final pad = GamepadController(id: 'a', name: 'A', plugin: platform);
    addTearDown(() async {
      await pad.dispose();
      await platform.dispose();
    });
    for (final value in [-1.0, 1.1, double.nan, double.infinity]) {
      expect(() => pad.rumble(lowFrequency: value), throwsArgumentError);
      expect(() => pad.rumble(highFrequency: value), throwsArgumentError);
    }
    for (final ms in [-1, 30001]) {
      expect(
        () => pad.rumble(duration: Duration(milliseconds: ms)),
        throwsArgumentError,
      );
    }
    expect(platform.calls, isEmpty);
  });
}
