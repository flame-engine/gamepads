import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:gamepads_test/gamepads_test.dart';

const aKey = Key('A');
const movementKey = Key('Movement');

void main() {
  testWidgets('My test', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    GamepadsTester.setNormalizer(GamepadPlatform.windows);

    await tester.pumpWidget(const MyGame());

    expect(find.byKey(aKey), findsNothing);
    expect(find.byKey(movementKey), findsNothing);

    GamepadsTester.emitRawButtonPress('a');
    await tester.pumpAndSettle();
    // Widget aKey should now be visible
    expect(find.byKey(aKey), findsOne);
    expect(find.byKey(movementKey), findsNothing);

    GamepadsTester.emitRawAnalog('leftThumbstickX', 0.7);
    await tester.pumpAndSettle();
    // Widget movementKey should now be visible
    expect(find.byKey(aKey), findsOne);
    expect(find.byKey(movementKey), findsOne);
  });
}

class MyGame extends StatefulWidget {
  const MyGame({super.key});

  @override
  State<MyGame> createState() => _MyGameState();
}

class _MyGameState extends State<MyGame> {
  late StreamSubscription<NormalizedGamepadEvent> unsubscribe;
  bool enableA = false;
  bool enableMovement = false;

  @override
  void initState() {
    super.initState();
    unsubscribe = Gamepads.normalizedEvents.listen(onGamepadEvent);
  }

  @override
  void dispose() {
    unsubscribe.cancel();
    super.dispose();
  }

  void onGamepadEvent(NormalizedGamepadEvent event) {
    if (event.button == GamepadButton.a && event.value == 1) {
      setState(() => enableA = true);
    }
    if (event.axis == GamepadAxis.leftStickX && event.value.abs() > 0.1) {
      setState(() => enableMovement = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            if (enableA) const Text('A enabled', key: aKey),
            if (enableMovement) const Text('Is moving', key: movementKey),
          ],
        ),
      ),
    );
  }
}
