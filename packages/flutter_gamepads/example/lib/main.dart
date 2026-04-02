import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/flame_example/main.dart';
import 'package:flutter_gamepads_example/flutter_example/main.dart';

void main() {
  runApp(const ChooserApp());
}

/// Description of example apps
enum Example {
  flutter('Flutter Example', 'A pure Flutter example'),
  flame('Flame Example', 'A Flame game with overlays');

  const Example(this.label, this.description);

  final String label;
  final String description;

  Widget imageBuilder(BuildContext context) {
    return switch (this) {
      Example.flame => Image.asset('assets/images/spaceship.png'),
      Example.flutter => const FlutterLogo(size: 32),
    };
  }

  Widget exampleAppBuilder(BuildContext context, void Function() exitApp) {
    return switch (this) {
      Example.flame => MyFlameApp(exitApp: exitApp),
      Example.flutter => MyFlutterApp(exitApp: exitApp),
    };
  }
}

/// A chooser app that lets user select between two example apps:
/// * Flutter example
/// * Flame example
class ChooserApp extends StatefulWidget {
  const ChooserApp({super.key});

  @override
  State<ChooserApp> createState() => _ChooserAppState();
}

class _ChooserAppState extends State<ChooserApp> {
  Example? selectedExample;

  @override
  Widget build(BuildContext context) {
    return switch (selectedExample) {
      (final Example example) => example.exampleAppBuilder(context, exitApp),
      null => buildExampleSelectionUi(context),
    };
  }

  Widget buildExampleSelectionUi(BuildContext context) {
    // The GamepadControl widget provides user ability to control the UI
    // with their gamepad.
    //
    // It has to sit here in buildEXampleSelectionUI so that it doesn't
    // build when one of the example apps builds as they provide their
    // own setup with a GamepadControl.
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
                  (example) => buildExampleButton(context, example),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildExampleButton(BuildContext context, Example example) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FilledButton(
        onPressed: () {
          setState(() => selectedExample = example);
        },
        child: Column(
          children: [
            example.imageBuilder(context),
            Text(
              example.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(example.description),
          ],
        ),
      ),
    );
  }

  /// Exit selected example app
  void exitApp() {
    setState(() {
      selectedExample = null;
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
          // An expressive border for focused buttons makes it easier to
          // use the chooser app with gamepad and keyboard input.
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
