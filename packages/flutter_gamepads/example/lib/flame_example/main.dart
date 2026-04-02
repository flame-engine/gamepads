import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/help_overlay.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/statusbar.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/upgrade_overlay.dart';
import 'package:flutter_gamepads_example/flame_example/theme.dart';

void main() {
  runApp(const MyFlameApp());
}

class MyFlameApp extends StatelessWidget {
  /// Callback provided by the Example chooser that allow the
  /// example to signal that user wants to exit the example.
  final void Function()? exitApp;
  const MyFlameApp({this.exitApp, super.key});

  @override
  Widget build(BuildContext context) {
    final game = MyGame(exitApp);
    return MaterialApp(
      theme: buildTheme(),
      home: GamepadControl(
        // An alternative to closing dialogs globally here is to wrap
        // each dialog with a GamepadInterceptor to be able to locally
        // catch the DismissIntent there. That option can be useful if
        // you need to prevent closing in some situations.
        onBeforeIntent: (activator, intent) {
          if (intent is DismissIntent && game.anyDialogOpen) {
            game.hideAllDialogs();
            return false;
          }
          return true;
        },
        child: GameWidget(
          game: game,
          initialActiveOverlays: [MyOverlays.statusbar.name],
          overlayBuilderMap: {
            MyOverlays.help.name: (context, MyGame game) => HelpOverlay(game),
            MyOverlays.statusbar.name: (context, MyGame game) =>
                StatusBarOverlay(game),
            MyOverlays.upgrade.name: (context, MyGame game) =>
                UpgradeOverlay(game),
          },
        ),
      ),
    );
  }
}
