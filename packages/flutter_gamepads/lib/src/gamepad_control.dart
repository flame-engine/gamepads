import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gamepads/src/gamepad_activator.dart';
import 'package:gamepads/gamepads.dart';

/// Wrap your widget tree with this widget to allow users
/// to navigate it using their gamepad.
///
/// Make sure your theme is setup so that widgets get a clear
/// visual indicator when they are focused.
class GamepadControl extends StatefulWidget {
  final Widget child;
  final bool ignoreEvents;
  final bool Function(Intent)? onBeforeIntent;

  final Map<GamepadActivator, Intent> shortcuts;

  const GamepadControl({
    required this.child,

    /// Called just before an Intent is invoked. Return false to block
    /// emitting the Intent.
    this.onBeforeIntent,

    /// If set to true, the gamepad control is temporarily disabled. It still
    /// listen on the gamepad, but just ignores the events.
    this.ignoreEvents = false,

    /// Configures the bindings between Gamepad activator (button or axis)
    /// and intents to invoke.
    ///
    /// References of available intents can be found by looking up
    /// [WidgetsApp.defaultShortcuts], which contains the default keyboard
    /// shortcuts used in apps.
    this.shortcuts = const {
      GamepadActivatorButton.a(): ActivateIntent(),
      GamepadActivatorButton.b(): DismissIntent(),
      GamepadActivatorButton.dpadUp(): PreviousFocusIntent(),
      GamepadActivatorButton.dpadLeft(): PreviousFocusIntent(),
      GamepadActivatorButton.dpadDown(): NextFocusIntent(),
      GamepadActivatorButton.dpadRight(): NextFocusIntent(),
      GamepadActivatorAxis.rightStickUp(): ScrollIntent(
        direction: AxisDirection.up,
      ),
      GamepadActivatorAxis.rightStickLeft(): ScrollIntent(
        direction: AxisDirection.left,
      ),
      GamepadActivatorAxis.rightStickDown(): ScrollIntent(
        direction: AxisDirection.down,
      ),
      GamepadActivatorAxis.rightStickRight(): ScrollIntent(
        direction: AxisDirection.right,
      ),
      GamepadActivatorAxis.leftStickLeft(): DirectionalFocusIntent(
        TraversalDirection.left,
      ),
      GamepadActivatorAxis.leftStickRight(): DirectionalFocusIntent(
        TraversalDirection.right,
      ),
      GamepadActivatorAxis.leftStickDown(): DirectionalFocusIntent(
        TraversalDirection.down,
      ),
      GamepadActivatorAxis.leftStickUp(): DirectionalFocusIntent(
        TraversalDirection.up,
      ),
    },

    super.key,
  });

  @override
  State<GamepadControl> createState() => _GamepadControlState();
}

class _GamepadControlState extends State<GamepadControl> {
  StreamSubscription? _subscription;

  /// abs() of the lowest minThreshold of any GamepadActivatorAxis
  /// used by a shortcut or null if there are no axis shortcuts.
  double? _minAxisThreshold;
  final Map<GamepadAxis, double> previousAxisValue = {};

  @override
  void initState() {
    super.initState();
    _subscription = Gamepads.normalizedEvents.listen(onGamepadEvent);
    _minAxisThreshold = _resolveMinAxisThreshold();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GamepadControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _minAxisThreshold = _resolveMinAxisThreshold();
    if (widget.ignoreEvents) {
      previousAxisValue.clear();
    }
  }

  double? _resolveMinAxisThreshold() {
    return widget.shortcuts.keys.fold<double?>(null, (
      double? prev,
      GamepadActivator activator,
    ) {
      switch (activator) {
        case final GamepadActivatorAxis axisActivator:
          final absActivatorMinThreshold = axisActivator.minThreshold.abs();
          if (prev == null) {
            return absActivatorMinThreshold;
          }
          if (absActivatorMinThreshold < prev) {
            return absActivatorMinThreshold;
          }
        case _:
          break;
      }
      return prev;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void onGamepadEvent(NormalizedGamepadEvent event) {
    if (widget.ignoreEvents == true) {
      return;
    }
    final intent = _find(event);
    if (intent == null) {
      _updatePreviousAxisValues(event);
      return;
    }
    // Same lookup as ShortcutManager.handleKeypress
    final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
    final focusedContext = primaryFocus?.context;
    // Allow previous/next to use parent context when focusContext is null
    // to allow user to focus something even when there is no autofocus.
    final activateContext =
        focusedContext ??
        ((intent is PreviousFocusIntent || intent is NextFocusIntent)
            ? context
            : null);
    if (activateContext != null) {
      var emitEvent = true;
      if (widget.onBeforeIntent != null) {
        emitEvent = widget.onBeforeIntent!(intent);
      }
      if (emitEvent) {
        if (intent is PreviousFocusIntent) {
          FocusScope.of(activateContext).previousFocus();
        } else if (intent is NextFocusIntent) {
          FocusScope.of(activateContext).nextFocus();
        } else {
          Actions.maybeInvoke(activateContext, intent);
        }
      }
    }

    _updatePreviousAxisValues(event);
  }

  Intent? _find(NormalizedGamepadEvent event) {
    final buttonPressed = event.button != null && event.value != 0;
    final axisMaybeActive =
        event.axis != null &&
        _minAxisThreshold != null &&
        event.value.abs() > _minAxisThreshold!.abs();
    if (!buttonPressed && !axisMaybeActive) {
      return null;
    }

    for (final entry in widget.shortcuts.entries) {
      final activator = entry.key;
      switch (activator) {
        case final GamepadActivatorButton buttonActivator:
          if (buttonActivator.button == event.button) {
            return entry.value;
          }
        case final GamepadActivatorAxis axisActivator:
          if (axisActivator.axis == event.axis) {
            final activatorSign = axisActivator.minThreshold > 0;
            final inputSign = event.value > 0;
            if (activatorSign == inputSign &&
                event.value.abs() > axisActivator.minThreshold.abs() &&
                (!previousAxisValue.containsKey(axisActivator.axis) ||
                    previousAxisValue[axisActivator.axis]!.abs() <=
                        axisActivator.minThreshold.abs())) {
              return entry.value;
            }
          }
      }
    }
    return null;
  }

  void _updatePreviousAxisValues(NormalizedGamepadEvent event) {
    if (event.axis != null) {
      previousAxisValue[event.axis!] = event.value;
    }
  }
}
