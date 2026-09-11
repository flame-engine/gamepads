# Example


## Basic example

```dart
void main() {
  testWidgets('My test', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    GamepadsTester.setNormalizer(GamepadPlatform.windows);

    await tester.pumpWidget(MyApp());

    GamepadsTester.emitButtonPress('a');
    await tester.pumpAndSettle();
    GamepadsTester.emitAnalog('leftThumbstickX', 0.7);
    await tester.pumpAndSettle();

    // Test that expected thing has happened
  });
}
```


## Full example

See [example_test.dart](../test/example_test.dart) for a full example for a simplistic
Flutter app.
