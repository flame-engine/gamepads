import 'package:flutter/material.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_example/flame_example/state/game_state.dart';

class UpgradeOverlay extends StatelessWidget {
  final MyGame game;
  const UpgradeOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: AlertDialog(
        title: const Text('Upgrades'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ValueListenableBuilder(
            valueListenable: game.gameState.powerUps,
            builder: (context, powerUps, child) {
              if (powerUps > 0) {
                return UpgradesList(game);
              }
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No PowerUp credits available, collect some power ups'
                    ' with your spaceship.',
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          FilledButton(
            autofocus: true,
            onPressed: () {
              game.hideOverlay(MyOverlays.upgrade);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class UpgradesList extends StatelessWidget {
  final MyGame game;
  const UpgradesList(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: game.gameState.installedUpgrades,
      builder: (context, installedUpgrades, child) {
        return ListView(
          children: [
            ...SpaceshipUpgrades.values.map(
              (upgrade) => Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: FilledButton(
                  onPressed: installedUpgrades.contains(upgrade)
                      ? null
                      : () {
                          game.gameState.installedUpgrades.value = {
                            ...installedUpgrades,
                            upgrade,
                          };
                          game.gameState.powerUps.value -= 1;
                          game.hideOverlay(MyOverlays.upgrade);
                        },
                  child: Text(upgrade.name),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
