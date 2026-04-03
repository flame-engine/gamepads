import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gamepads/src/gamepad_control.dart';
import 'package:flutter_gamepads/src/gamepad_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamepads/gamepads.dart';

import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';

final platformInterface =
    GamepadsPlatformInterface.instance
        as MethodChannelGamepadsPlatformInterface;

enum _UiButton { noButton, first, second }

void main() {
  Gamepads.normalizer = GamepadNormalizer.forPlatform(
    GamepadPlatform.windows,
  );

  testWidgets('GamepadControl', (WidgetTester tester) async {
    var lastButtonPressed = _UiButton.noButton;
    var beforeInvokeActivate = false;
    var beforeInvokeDismiss = false;
    final aFocusNode = FocusNode();
    final bFocusNode = FocusNode();
    final ignoreEvents = ValueNotifier<bool>(false);
    var emitIntents = true;

    final widget = MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: ignoreEvents,
        builder: (context, value, child) {
          return GamepadControl(
            onBeforeIntent: (activator, intent) {
              if (intent is ActivateIntent) {
                beforeInvokeActivate = true;
              } else if (intent is DismissIntent) {
                beforeInvokeDismiss = true;
              }
              return emitIntents;
            },
            ignoreEvents: ignoreEvents.value,
            child: Column(
              children: [
                ElevatedButton(
                  focusNode: aFocusNode,
                  onPressed: () => lastButtonPressed = _UiButton.first,
                  child: const Text('First'),
                ),
                ElevatedButton(
                  focusNode: bFocusNode,
                  onPressed: () => lastButtonPressed = _UiButton.second,
                  child: const Text('Second'),
                ),
              ],
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(widget);
    await _keyPress('dpadDown');
    await tester.pumpAndSettle();

    // First UI button has focus
    expect(aFocusNode.hasFocus, isTrue);
    expect(lastButtonPressed, equals(_UiButton.noButton));
    expect(beforeInvokeActivate, isFalse);

    // Emit 'a' gamepad button => should press the first UI button
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(aFocusNode.hasFocus, isTrue);
    expect(lastButtonPressed, equals(_UiButton.first));
    expect(beforeInvokeActivate, isTrue);
    expect(beforeInvokeDismiss, isFalse);

    // Emit 'dpadRight' gamepad button => should focus second UI button
    beforeInvokeActivate = false;
    lastButtonPressed = _UiButton.noButton;
    await _keyPress('dpadRight');
    await tester.pumpAndSettle();
    expect(bFocusNode.hasFocus, isTrue);
    expect(lastButtonPressed, equals(_UiButton.noButton));
    expect(beforeInvokeActivate, isFalse);
    expect(beforeInvokeDismiss, isFalse);

    // Emit 'a' gamepad button => should press the second UI button
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(bFocusNode.hasFocus, isTrue);
    expect(lastButtonPressed, equals(_UiButton.second));
    expect(beforeInvokeActivate, isTrue);
    expect(beforeInvokeDismiss, isFalse);

    // Emit 'b' gamepad button => should call onBeforeInvoke with dismiss intent
    beforeInvokeActivate = false;
    lastButtonPressed = _UiButton.noButton;
    await _keyPress('b');
    await tester.pumpAndSettle();
    expect(lastButtonPressed, equals(_UiButton.noButton));
    expect(beforeInvokeActivate, isFalse);
    expect(beforeInvokeDismiss, isTrue);

    // allow events, but returning false from onBeforeIntent should block intent
    emitIntents = false;
    beforeInvokeActivate = false;
    beforeInvokeDismiss = false;
    lastButtonPressed = _UiButton.noButton;
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(lastButtonPressed, equals(_UiButton.noButton));
    expect(beforeInvokeActivate, isTrue);
    expect(beforeInvokeDismiss, isFalse);

    // ignore events => should not even call onBeforeIntent or invoke any thing
    ignoreEvents.value = true;
    emitIntents = true;
    await tester.pumpAndSettle();
    beforeInvokeActivate = false;
    beforeInvokeDismiss = false;
    lastButtonPressed = _UiButton.noButton;
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(lastButtonPressed, equals(_UiButton.noButton));
    expect(beforeInvokeActivate, isFalse);
    expect(beforeInvokeDismiss, isFalse);
  });

  testWidgets('GamepadInterceptor', (WidgetTester tester) async {
    var rootBeforeIntentCalled = false;
    var rootEmit = true;
    var interceptorBeforeIntentCalled = false;
    var interceptorEmit = true;
    final secondFocusNode = FocusNode();
    var secondPressed = false;
    final widget = MaterialApp(
      home: GamepadControl(
        onBeforeIntent: (activator, intent) {
          rootBeforeIntentCalled = true;
          return rootEmit;
        },
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => {},
              child: const Text('Button'),
            ),
            GamepadInterceptor(
              onBeforeIntent: (activator, intent) {
                interceptorBeforeIntentCalled = true;
                return interceptorEmit;
              },
              child: ElevatedButton(
                focusNode: secondFocusNode,
                onPressed: () {
                  secondPressed = true;
                },
                child: const Text('Second'),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await _keyPress('dpadDown');
    await _keyPress('dpadDown');
    await tester.pumpAndSettle();

    expect(secondFocusNode.hasFocus, isTrue);
    expect(secondPressed, isFalse);

    // Emit gamepad event => should call both onBeforeIntent
    rootBeforeIntentCalled = false;
    interceptorBeforeIntentCalled = false;
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(rootBeforeIntentCalled, isTrue);
    expect(interceptorBeforeIntentCalled, isTrue);
    expect(secondPressed, isTrue);

    // Return false only from the root onBeforeIntent
    rootEmit = false;
    rootBeforeIntentCalled = false;
    interceptorBeforeIntentCalled = false;
    secondPressed = false;
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(rootBeforeIntentCalled, isTrue);
    expect(interceptorBeforeIntentCalled, isTrue);
    expect(secondPressed, isFalse);

    // Return false only from the interceptor onBeforeIntent
    rootEmit = true;
    interceptorEmit = false;
    rootBeforeIntentCalled = false;
    interceptorBeforeIntentCalled = false;
    await _keyPress('a');
    await tester.pumpAndSettle();
    expect(rootBeforeIntentCalled, isFalse);
    expect(interceptorBeforeIntentCalled, isTrue);
    expect(secondPressed, isFalse);
  });
}

Future<void> _keyPress(String key) async {
  await _event(key, 1.0);
  await _event(key, 0.0);
}

Future<void> _event(String key, double value) async {
  final millis = DateTime.now().millisecondsSinceEpoch;
  await platformInterface.platformCallHandler(
    MethodCall('onGamepadEvent', <String, dynamic>{
      'gamepadId': '1',
      'time': millis,
      'type': 'button',
      'key': key,
      'value': value,
    }),
  );
}
