import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_example/flame_example/state/game_state.dart';
import 'package:flutter_gamepads_example/flame_example/world.dart';

class MyGame extends FlameGame with HasKeyboardHandlerComponents {
  final GameState gameState = GameState();
  final void Function()? exitApp;

  MyGame(this.exitApp) : super(world: MyWorld());

  bool get anyDialogOpen =>
      overlays.activeOverlays.contains(MyOverlays.help.name) ||
      overlays.activeOverlays.contains(MyOverlays.upgrade.name);

  void updateEnginePause() {
    final shouldBePaused = gameState.userPaused.value || anyDialogOpen;
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
