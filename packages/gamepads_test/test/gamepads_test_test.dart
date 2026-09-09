import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import 'package:gamepads_test/gamepads_test.dart';

void main() {
  testWidgets('GamepadTester', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    GamepadsTester.setNormalizer(GamepadPlatform.windows);
    expect(Gamepads.normalizer, isNotNull);
    List<GamepadEvent> events = [];
    List<NormalizedGamepadEvent> normalizedEvents = [];
    Gamepads.events.listen((event) {
      events.add(event);
    });
    Gamepads.normalizedEvents.listen((event) {
      normalizedEvents.add(event);
    });
    await tester.pumpAndSettle();
    expect(events, isEmpty);
    expect(normalizedEvents, isEmpty);

    GamepadsTester.emitRawButton('a', 1.0);
    await tester.pumpAndSettle();
    expect(events, hasLength(1));
    expect(normalizedEvents, hasLength(1));
    expect(events[0].key, equals('a'));
    expect(events[0].type, equals(KeyType.button));
    expect(
      events[0].timestamp,
      lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch),
    );
    expect(events[0].value, equals(1.0));
    expect(normalizedEvents[0].button, equals(GamepadButton.a));
    expect(normalizedEvents[0].axis, isNull);
    expect(normalizedEvents[0].value, equals(1.0));

    events.clear();
    normalizedEvents.clear();

    GamepadsTester.emitRawAnalog('leftThumbstickX', 0.75);
    await tester.pumpAndSettle();
    expect(events, hasLength(1));
    expect(normalizedEvents, hasLength(1));
    expect(events[0].key, equals('leftThumbstickX'));
    expect(events[0].type, equals(KeyType.analog));
    expect(
      events[0].timestamp,
      lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch),
    );
    expect(events[0].value, equals(0.75));
    expect(normalizedEvents[0].button, isNull);
    expect(normalizedEvents[0].axis, equals(GamepadAxis.leftStickX));
    expect(normalizedEvents[0].value, equals(0.75));

    events.clear();
    normalizedEvents.clear();

    GamepadsTester.emitRawButtonPress('x');
    await tester.pumpAndSettle();
    expect(events, hasLength(2));
    expect(normalizedEvents, hasLength(2));
    expect(events[0].key, equals('x'));
    expect(events[0].type, equals(KeyType.button));
    expect(events[0].value, equals(1.0));
    expect(normalizedEvents[0].button, equals(GamepadButton.x));
    expect(normalizedEvents[0].axis, isNull);
    expect(normalizedEvents[0].value, equals(1.0));
    expect(events[1].key, equals('x'));
    expect(events[1].type, equals(KeyType.button));
    expect(events[1].value, equals(0.0));
    expect(normalizedEvents[1].button, equals(GamepadButton.x));
    expect(normalizedEvents[1].axis, isNull);
    expect(normalizedEvents[1].value, equals(0.0));
    expect(events[1].timestamp, greaterThanOrEqualTo(events[0].timestamp));
  });
}
