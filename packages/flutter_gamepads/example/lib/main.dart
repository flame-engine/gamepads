import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/flame_example/main.dart';
import 'package:flutter_gamepads_example/flutter_example/main.dart';

void main() {
  runApp(const ChooserApp());
}

enum Example {
  flutter('A pure Flutter example'),
  flame('A Flame game example');

  const Example(this.description);

  final String description;
}

class ChooserApp extends StatefulWidget {
  const ChooserApp({super.key});

  @override
  State<ChooserApp> createState() => _ChooserAppState();
}

class _ChooserAppState extends State<ChooserApp> {
  Example? example;

  @override
  Widget build(BuildContext context) {
    return switch (example) {
      Example.flame => MyFlameApp(exitApp: exitApp),
      Example.flutter => MyFlutterApp(exitApp: exitApp),
      null => buildSelectionUi(context),
    };
  }

  Widget buildSelectionUi(BuildContext context) {
    return GamepadControl(
      child: MaterialApp(
        theme: _theme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Choose an Example app',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(color: Colors.white),
                ),
                ...Example.values.map(
                  (ex) => Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: FilledButton(
                      onPressed: () {
                        setState(() => example = ex);
                      },
                      child: Column(
                        children: [
                          Text(
                            ex.name[0].toUpperCase() + ex.name.substring(1),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(ex.description),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void exitApp() {
    setState(() {
      example = null;
    });
  }
}

ThemeData get _theme =>
    ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.dark,
      ),
    ).copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.all(30)),
          side: WidgetStateProperty.resolveWith((state) {
            return state.contains(WidgetState.focused)
                ? BorderSide(
                    color: Colors.deepOrange[800]!,
                    width: 5,
                    strokeAlign: 3,
                  )
                : BorderSide.none;
          }),
        ),
      ),
    );
