import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:gamepads/gamepads.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.indigo[200],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentGeometry.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.chevron_left, semanticLabel: 'Close'),
                ),
              ),
              const SizedBox(height: 50),
              FilledButton(
                autofocus: true,
                onPressed: () => onGotoSettings(context),
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Flutter Gamepads sample app'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('A short sample app for flutter gamepads testing'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => onShowGame(context),
            child: const Text('Play game'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => onShowDialog(context),
            child: const Text('Show dialog'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => onShowSnackbar(context),
            child: const Text('Show snackbar'),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controls',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                    },
                    children: [
                      ...gamepadInfo(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TableRow> gamepadInfo() {
    final shortcuts = GamepadControl(child: Container()).shortcuts;
    return shortcuts.keys.map((key) {
      var activator = '';
      if (key is GamepadActivatorButton) {
        activator += 'Button ${key.button.name}';
      } else if (key is GamepadActivatorAxis) {
        activator += 'Axis ${key.axis.name}';
      }

      final intent = shortcuts[key];
      final intentText = intent.toString().split('Intent')[0];

      return TableRow(
        children: [
          Text(activator),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text('→   $intentText'),
          ),
        ],
      );
    }).toList();
  }

  void onShowGame(BuildContext context) {
    Navigator.of(context).pushNamed('/game');
  }

  void onShowDialog(BuildContext context) {
    final controller = ScrollController();
    showDialog(
      context: context,
      builder: (context) => GamepadInterceptor(
        onBeforeIntent: (activator, intent) {
          // The ListView just contains text and never therefore receives focus.
          // Using GamepadInterceptor we can still support scrolling this
          // ListView.
          if (intent is ScrollIntent) {
            if (intent.direction == AxisDirection.up) {
              controller.jumpTo(controller.offset - 100);
            } else if (intent.direction == AxisDirection.down) {
              controller.jumpTo(controller.offset + 100.0);
            }
            return false;
          }
          return true;
        },
        child: AlertDialog(
          title: const Text('List of gamepad buttons'),
          content: SizedBox(
            height: 200,
            width: 200,
            child: ListView(
              controller: controller,
              children: GamepadButton.values.map((b) => Text(b.name)).toList(),
            ),
          ),
          actions: [
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void onShowSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Primary action triggered')),
    );
  }

  void onGotoSettings(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed('/settings');
  }
}
