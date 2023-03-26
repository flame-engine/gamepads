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

  String _lastEvent = '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamepads Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              stream: _gamepad.gamepadEventsStream,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data != null) {
                  _lastEvent = data.value;
                }
                return Text('Last Event: $_lastEvent');
              },
            ),
            Text('Result: ${_response.map((e) => e.id)}'),
            TextButton(
              onPressed: _getValue,
              child: const Text('listGamepads()'),
            ),
          ],
        ),
      ),
    );
  }
}
