import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamepads Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final _gamepad = Gamepad();

  StreamSubscription<GamepadEvent>? _subscription;

  List<GamepadEvent> _lastEvents = [];
  bool loading = false;
  List<GamepadController> _response = [];

  Future<void> _getValue() async {
    setState(() => loading = true);
    final response = await _gamepad.listGamepads();
    setState(() {
      _response = response;
      loading = false;
    });
  }

  void _clear() {
    setState(() => _lastEvents = []);
  }

  @override
  void initState() {
    super.initState();
    _subscription = _gamepad.gamepadEventsStream.listen((event) {
      setState(() {
        final newEvents = [
          event,
          ..._lastEvents,
        ];
        if (newEvents.length > 3) {
          newEvents.removeRange(3, newEvents.length);
        }
        _lastEvents = newEvents;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamepads Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Last Events:'),
            ..._lastEvents.map((e) => Text(e.toString())),
            TextButton(
              onPressed: _clear,
              child: const Text('clear events'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _getValue,
              child: const Text('listGamepads()'),
            ),
            Text('Result: ${_response.map((e) => e.id)}'),
          ],
        ),
      ),
    );
  }
}
