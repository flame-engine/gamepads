import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('xyz.luan/gamepads');
  final calls = <MethodCall>[];
  final platform = MethodChannelGamepadsPlatformInterface();

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  test('rumble sends device, both motors and a finite duration', () async {
    expect(
      await platform.rumble(
        'pad-2',
        lowFrequency: 0.25,
        highFrequency: 1,
        duration: const Duration(seconds: 30),
      ),
      isTrue,
    );
    expect(calls.single.method, 'rumble');
    expect(calls.single.arguments, <String, Object>{
      'gamepadId': 'pad-2',
      'lowFrequency': 0.25,
      'highFrequency': 1.0,
      'durationMillis': 30000,
    });
  });

  test(
    'rejects invalid amplitudes and durations before native dispatch',
    () async {
      for (final value in [-0.1, 1.1, double.nan, double.infinity]) {
        await expectLater(
          platform.rumble('pad', lowFrequency: value),
          throwsArgumentError,
        );
      }
      for (final ms in [-1, 30001]) {
        await expectLater(
          platform.rumble('pad', duration: Duration(milliseconds: ms)),
          throwsArgumentError,
        );
      }
      expect(calls, isEmpty);
    },
  );

  test('zero duration and explicit stop use the same device', () async {
    await platform.rumble('pad', duration: Duration.zero);
    await platform.stopRumble('pad');
    expect(calls.map((call) => call.method), ['stopRumble', 'stopRumble']);
    expect(calls.last.arguments, {'gamepadId': 'pad'});
  });

  test('an unavailable native backend reports unsupported', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw MissingPluginException(),
        );
    expect(await platform.hasRumble('pad'), isFalse);
    expect(await platform.rumble('pad'), isFalse);
    expect(await platform.stopRumble('pad'), isFalse);
  });
}
