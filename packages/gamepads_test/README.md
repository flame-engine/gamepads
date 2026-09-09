# gamepads_test

A utility package for [*gamepads*](https://pub.dev/packages/gamepads) to help writing tests.

Provides `GamepadsTester` which you can use to emit raw (non-normalized) events into the gamepads
event stream.

Given that the emitted events matches the raw one of the normalizer platform, gamepads will emit
also normalized events for your tested app code.


## Usage

```dart
void main() {
  testWidgets('My test', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    GamepadsTester.setNormalizer(.windows);

    await tester.pumpWidget(MyApp());

    GamepadsTester.emitRawButtonPress('a');
    await tester.pumpAndSettle()
    GamepadsTester.emitRawAnalog('leftThumbstickX', 0.7);
    await tester.pumpAndSettle()

    // Test that expected thing has happened
  });
}
```
