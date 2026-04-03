import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter_gamepads_example/flame_example/overlays/overlays.dart';
import 'package:flutter_gamepads_example/flame_example/state/game_state.dart';
import 'package:flutter_gamepads_example/flame_example/world.dart';

/// This is our flame game.
class MyGame extends FlameGame with HasKeyboardHandlerComponents {
  final GameState gameState = GameState();
  final void Function()? exitApp;

  MyGame(this.exitApp) : super(world: MyWorld());

  /// Is any dialog style overlay active?
  bool get anyDialogOpen =>
      overlays.activeOverlays.contains(MyOverlays.help.name) ||
      overlays.activeOverlays.contains(MyOverlays.upgrade.name);

  /// Update flame engine pause based on if the game should currently
  /// be paused or not.
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

  /// Show an overlay
  ///
  /// Automatically pauses the game engine if the overlay is a dialog
  /// according to [anyDialogOpen].
  void showOverlay(MyOverlays overlay) {
    overlays.add(overlay.name);
    updateEnginePause();
  }

  /// Hide an overlay
  ///
  /// Automatically unpauses the game if there are no longer any open dialogs
  /// according to [anyDialogOpen] and the user has not manually paused the
  /// game.
  void hideOverlay(MyOverlays overlay) {
    overlays.remove(overlay.name);
    updateEnginePause();
  }

  /// Close all dialog style overlays
  void hideAllDialogs() {
    overlays.removeAll([
      MyOverlays.help.name,
      MyOverlays.upgrade.name,
    ]);
    updateEnginePause();
  }
}
