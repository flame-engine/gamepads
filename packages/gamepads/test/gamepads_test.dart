import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamepads/gamepads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  const channel = MethodChannel('xyz.luan/gamepads');
  channel.setMockMethodCallHandler((MethodCall call) async {
    calls.add(call);
    return <GamepadController>[];
  });

  void clear() {
    calls.clear();
  }

  MethodCall popCall() {
    return calls.removeAt(0);
  }

  MethodCall popLastCall() {
    expect(calls, hasLength(1));
    return popCall();
  }

  setUp(clear);

  test('invokes listGamepads through platform interface', () async {
    final gamepad = Gamepad();
    expect(await gamepad.listGamepads(), <GamepadController>[]);
    expect(popLastCall().method, 'listGamepads');
  });
}
