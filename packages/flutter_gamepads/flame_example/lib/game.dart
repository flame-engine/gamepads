import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter_gamepads_flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_flame_example/state/game_state.dart';
import 'package:flutter_gamepads_flame_example/world.dart';

class MyGame extends FlameGame with HasKeyboardHandlerComponents {
  final GameState gameState = GameState();

  MyGame() : super(world: MyWorld());

  bool get anyDialogOpen =>
      overlays.activeOverlays.contains(MyOverlays.help.name) ||
      overlays.activeOverlays.contains(MyOverlays.upgrade.name);

  void updateEnginePause() {
    final shouldBePaused =
        gameState.userPaused.value || anyDialogOpen;
    if (shouldBePaused != paused) {
      if (shouldBePaused) {
        pauseEngine();
      } else {
        resumeEngine();
      }
    }
  }

  void showOverlay(MyOverlays overlay) {
    overlays.add(overlay.name);
    updateEnginePause();
  }

  void hideOverlay(MyOverlays overlay) {
    overlays.remove(overlay.name);
    updateEnginePause();
  }

  void hideAllDialogs() {
    overlays.removeAll([
      MyOverlays.help.name,
      MyOverlays.upgrade.name,
    ]);
    updateEnginePause();
  }
}
