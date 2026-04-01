import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/help_overlay.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/statusbar.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/upgrade_overlay.dart';

void main() {
  runApp(const MyFlameApp());
}

class MyFlameApp extends StatelessWidget {
  final void Function()? exitApp;
  const MyFlameApp({this.exitApp, super.key});

  @override
  Widget build(BuildContext context) {
    final game = MyGame(exitApp);
    return MaterialApp(
      theme:
          ThemeData.from(
            colorScheme: ColorScheme.dark(
              primary: Colors.orange[700]!,
              surface: Color.lerp(Colors.orange[900], Colors.grey[800], 0.7)!,
            ),
          ).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(5),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: ButtonStyle(
                shape: WidgetStateProperty.resolveWith((state) {
                  return RoundedRectangleBorder(
                    side: BorderSide(
                      color: state.contains(WidgetState.focused)
                          ? Colors.lightGreenAccent
                          : Colors.transparent,
                      width: 4,
                      strokeAlign: -0.5,
                    ),
                    borderRadius: BorderRadiusGeometry.circular(
                      state.contains(WidgetState.focused) ? 2 : 5,
                    ),
                  );
                }),
              ),
            ),
          ),
      home: GamepadControl(
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
