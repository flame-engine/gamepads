import 'package:flutter/material.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlay_dialog_backdrop.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlays.dart';

class HelpOverlay extends StatelessWidget {
  final MyGame game;
  const HelpOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return OverlayDialogBackdrop(
      child: AlertDialog(
        title: const Text('Controls'),
        content: const Text(_bodyText),
        actions: [
          FilledButton(
            onPressed: () {
              game.hideOverlay(MyOverlays.help);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

const _bodyText = '''** Spaceship **
Turn left: A, LeftArrow, Gamepad left stick
Turn right: D, RightArrow, Gamepad left stick
Accelerate: W, UpArrow, Gamepad right trigger
Brake: D, DownArrow, Gamepad left trigger

Note: to brake, you need the turnRail upgrade.

** Gamepad UI controls **
Move focus: D-pad
Activate button: A
Close dialog: B
  ''';
