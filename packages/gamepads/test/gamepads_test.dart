import 'package:flutter_test/flutter_test.dart';

import 'package:gamepads/gamepads.dart';

void main() {
  test('adds one to input values', () async {
    final gamepad = Gamepad();
    expect(await gamepad.getValue(), 42);
  });
}
