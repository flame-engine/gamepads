import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamepads/gamepads.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  const channel = MethodChannel('xyz.luan/gamepads');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          calls.add(methodCall);
          return <GamepadController>[];
        },
      );

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

  final platformInterface =
      GamepadsPlatformInterface.instance
          as MethodChannelGamepadsPlatformInterface;

  setUp(clear);

  test('invokes listGamepads through platform interface', () async {
    expect(await Gamepads.list(), <GamepadController>[]);
    expect(popLastCall().method, 'listGamepads');
  });

  test('parses vendorId and productId', () async {
    final controller = GamepadController.parse(<String, dynamic>{
      'id': '1',
      'name': 'Test Gamepad',
      'vendorId': 0x054c,
      'productId': 0x0ce6,
    }, platformInterface);
    addTearDown(controller.dispose);

    expect(controller.vendorId, 0x054c);
    expect(controller.productId, 0x0ce6);
  });

  test('leaves vendorId and productId null when absent', () async {
    final controller = GamepadController.parse(<String, dynamic>{
      'id': '1',
      'name': 'Test Gamepad',
    }, platformInterface);
    addTearDown(controller.dispose);

    expect(controller.vendorId, isNull);
    expect(controller.productId, isNull);
  });

  test('can listen to events through platform interface', () async {
    final listener = Gamepads.events.first;
    final millis = DateTime.now().millisecondsSinceEpoch;
    await platformInterface.platformCallHandler(
      MethodCall(
        'onGamepadEvent',
        <String, dynamic>{
          'gamepadId': '1',
          'time': millis,
          'type': 'button',
          'key': 'a',
          'value': 1.0,
        },
      ),
    );
    final event = await listener;
    expect(event.gamepadId, '1');
    expect(event.timestamp, millis);
    expect(event.type, KeyType.button);
    expect(event.key, 'a');
    expect(event.value, 1.0);
  });

  test(
    'can listen to gamepad-specific events through platform interface',
    () async {
      final listener = Gamepads.eventsByGamepad('1').first;
      final millis = DateTime.now().millisecondsSinceEpoch;
      await platformInterface.platformCallHandler(
        MethodCall(
          'onGamepadEvent',
          <String, dynamic>{
            'gamepadId': '1',
            'time': millis,
            'type': 'button',
            'key': 'a',
            'value': 1.0,
          },
        ),
      );
      final event = await listener;
      expect(event.gamepadId, '1');
      expect(event.timestamp, millis);
      expect(event.type, KeyType.button);
      expect(event.key, 'a');
      expect(event.value, 1.0);
    },
  );

  test('can listen to connection events through platform interface', () async {
    final listener = Gamepads.connectionEvents.first;
    await platformInterface.platformCallHandler(
      const MethodCall(
        'onGamepadConnectionEvent',
        <String, dynamic>{
          'gamepadId': '1',
          'name': 'Test Controller',
          'type': 'connected',
        },
      ),
    );
    final event = await listener;
    expect(event.gamepadId, '1');
    expect(event.name, 'Test Controller');
    expect(event.type, GamepadConnectionEventType.connected);
  });

  test('onConnected only emits connection events', () async {
    final listener = Gamepads.onConnected.first;
    await platformInterface.platformCallHandler(
      const MethodCall(
        'onGamepadConnectionEvent',
        <String, dynamic>{
          'gamepadId': '1',
          'name': 'Test Controller',
          'type': 'disconnected',
        },
      ),
    );
    await platformInterface.platformCallHandler(
      const MethodCall(
        'onGamepadConnectionEvent',
        <String, dynamic>{
          'gamepadId': '2',
          'name': 'Other Controller',
          'type': 'connected',
        },
      ),
    );
    final event = await listener;
    expect(event.gamepadId, '2');
    expect(event.type, GamepadConnectionEventType.connected);
  });

  test('onDisconnected only emits disconnection events', () async {
    final listener = Gamepads.onDisconnected.first;
    await platformInterface.platformCallHandler(
      const MethodCall(
        'onGamepadConnectionEvent',
        <String, dynamic>{
          'gamepadId': '1',
          'name': 'Test Controller',
          'type': 'connected',
        },
      ),
    );
    await platformInterface.platformCallHandler(
      const MethodCall(
        'onGamepadConnectionEvent',
        <String, dynamic>{
          'gamepadId': '2',
          'name': 'Other Controller',
          'type': 'disconnected',
        },
      ),
    );
    final event = await listener;
    expect(event.gamepadId, '2');
    expect(event.type, GamepadConnectionEventType.disconnected);
  });
}
