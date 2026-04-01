import 'package:flutter/material.dart';
import 'package:flutter_gamepads_flame_example/game.dart';
import 'package:flutter_gamepads_flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_flame_example/state/game_state.dart';

class StatusBarOverlay extends StatefulWidget {
  final MyGame game;

  const StatusBarOverlay(this.game, {super.key});

  @override
  State<StatusBarOverlay> createState() => _StatusBarOverlayState();
}

class _StatusBarOverlayState extends State<StatusBarOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          FilledButton(
            onPressed: onTogglePause,
            child: ValueListenableBuilder(
              valueListenable: widget.game.gameState.userPaused,
              builder: (context, userPaused, child) {
                return Icon(userPaused ? Icons.play_arrow : Icons.pause);
              },
            ),
          ),
          const SizedBox(width: 5),
          FilledButton(
            onPressed: onShowUpgradeOverlay,
            child: ValueListenableBuilder(
              valueListenable: widget.game.gameState.powerUps,
              builder: (context, value, child) {
                return Row(
                  children: [
                    Image.asset('assets/images/power_up.png'),
                    Text('$value'),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 5),
          FilledButton(
            onPressed: onShowHelpOverlay,
            child: Text('Controls'),
          ),
        ],
      ),
    );
  }

  void onTogglePause() {
    widget.game.gameState.userPaused.value =
        !widget.game.gameState.userPaused.value;
    widget.game.updateEnginePause();
  }

  void onShowUpgradeOverlay() {
    widget.game.showOverlay(MyOverlays.upgrade);
  }

  void onShowHelpOverlay() {
    widget.game.showOverlay(MyOverlays.help);
  }
}
