import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  runApp(const MyApp());
}

/// This app has been AI generated which took a few attempts to iron out some
/// weirdness, but still can have some weird stuff in it.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Gamepads Demo',
      theme: baseTheme.copyWith(
        focusColor: Colors.orange,
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.orange,
              width: 3,
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Color(0x332196F3),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return const BorderSide(
                  color: Colors.orange,
                  width: 3,
                );
              }
              return BorderSide.none;
            }),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.index,
    required this.child,
    super.key,
  });

  final String title;
  final int index;
  final Widget child;

  void _goToPage(BuildContext context, int newIndex) {
    if (newIndex == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      Navigator.pushReplacementNamed(context, '/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GamepadControl(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => _goToPage(context, value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Flutter Gamepads sample app',
      index: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flutter Gamepads sample app',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A short sample app for flutter gamepad testing.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('List of gamepad buttons'),
                  content: SizedBox(
                    height: 200,
                    width: 200,
                    child: ListView(
                      children: GamepadButton.values
                          .map((b) => Text(b.name))
                          .toList(),
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Show dialog'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Primary action triggered')),
              );
            },
            child: const Text('Show snackbar'),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double volume = 50;
  bool vibrationEnabled = true;
  String selectedMode = 'Adventure';
  final TextEditingController nameController = TextEditingController(
    text: 'Player One',
  );

  final List<String> gameModes = ['Adventure', 'Arcade', 'Challenge'];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      index: 1,
      child: ListView(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Player name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Volume: ${volume.round()}'),
                  Slider(
                    value: volume,
                    max: 100,
                    divisions: 10,
                    label: volume.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        volume = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedMode,
            decoration: const InputDecoration(labelText: 'Game mode'),
            items: gameModes
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(mode),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                selectedMode = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable vibration'),
            value: vibrationEnabled,
            onChanged: (value) {
              setState(() {
                vibrationEnabled = value;
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Saved ${nameController.text} / $selectedMode / ${volume.round()}',
                  ),
                ),
              );
            },
            child: const Text('Save settings'),
          ),
        ],
      ),
    );
  }
}
