import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:gamepads/gamepads.dart';

/// Wrap your widget tree with this widget to allow users
/// to navigate it using their gamepad.
///
/// Make sure your theme is setup so that widgets get a clear
/// visual indicator when they are focused.
class GamepadControl extends StatefulWidget {
  final Widget child;
  final bool ignoreEvents;
  final bool Function(GamepadActivator, Intent)? onBeforeIntent;

  final Map<GamepadActivator, Intent> shortcuts;

  final Duration initialRepeatDelay;
  final Duration repeatedRepeatDelay;

  const GamepadControl({
    required this.child,

    /// Called just before an Intent is invoked. Return false to block
    /// emitting the Intent.
    ///
    /// Additionally, you can wrap something deep in your tree with
    /// [GamepadInterceptor] widget to receive onBeforeIntent locally
    /// in that build context.
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
    },

    /// Delay after first input until first input repeat occurs.
    this.initialRepeatDelay = const Duration(milliseconds: 700),

    /// Delay after the first input repetition to the next reptilton and beyond.
    this.repeatedRepeatDelay = const Duration(milliseconds: 200),

    super.key,
  });

  @override
  State<GamepadControl> createState() => _GamepadControlState();
}

class _GamepadControlState extends State<GamepadControl> {
  StreamSubscription? _subscription;

  final Map<GamepadAxis, double> _previousAxisValue = {};
  final Map<Intent, Timer> _repeat = {};

  @override
  void initState() {
    super.initState();
    _subscription = Gamepads.normalizedEvents.listen(onGamepadEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repeat.values.forEach((timer) {
      timer.cancel();
    });
    _repeat.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GamepadControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ignoreEvents) {
      _previousAxisValue.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void onGamepadEvent(NormalizedGamepadEvent event) {
    if (widget.ignoreEvents == true) {
      return;
    }
    final intents = _find(event);
    for (final (activator, intent, activated, canceled) in intents) {
      if (canceled) {
        _repeat[intent]?.cancel();
        _repeat.remove(intent);
      }
      if (activated) {
        _maybeInvokeIntent(activator, intent, const Duration(milliseconds: 700));
      }
    }
    _updatePreviousAxisValues(event);
  }

  /// Find intents that match the given gamepad event.
  ///
  /// Return list of (Intent, activated, canceled)
  List<(GamepadActivator, Intent, bool, bool)> _find(NormalizedGamepadEvent event) {
    final result = <(GamepadActivator, Intent, bool, bool)>[];
    for (final entry in widget.shortcuts.entries) {
      final activator = entry.key;
      switch (activator) {
        case final GamepadActivatorButton buttonActivator:
          if (buttonActivator.button == event.button) {
            result.add((activator, entry.value, event.value != 0, event.value == 0));
          }
        case final GamepadActivatorAxis axisActivator:
          if (axisActivator.axis == event.axis) {
            final activatorSign = axisActivator.minThreshold > 0;
            final inputSign = event.value > 0;
            // Axis is activated when moving to from below Threshold to
            // above it.
            final axisActivated =
                activatorSign == inputSign &&
                event.value.abs() > axisActivator.minThreshold.abs() &&
                (!_previousAxisValue.containsKey(axisActivator.axis) ||
                    _previousAxisValue[axisActivator.axis]!.abs() <=
                        axisActivator.minThreshold.abs());
            // Cancel is easier as duplicate cancels is not an issue.
            final axisCanceled = axisActivator.minThreshold > 0
                ? event.value <= axisActivator.minThreshold
                : event.value >= axisActivator.minThreshold;
            result.add((activator, entry.value, axisActivated, axisCanceled));
          }
      }
    }
    return result;
  }

  /// Invoke [intent] on target context if it is not being blocked by
  /// onBeforeInvoke or CallbackInterceptor.onBeforeInvoke. Also
  /// schedule a repeat after [repeatDuration].
  void _maybeInvokeIntent(
    GamepadActivator activator,
    Intent intent, Duration repeatDuration) {
    final activateContext = _resolveInvokeContext(intent);
    if (activateContext != null) {
      // Activate the timer before calling _allowInvoke so that interceptors
      // receive repeated input.
      _repeat[intent] = Timer(
        repeatDuration,
        () => _onRepeat(activator, intent),
      );
      final allowInvoke = _allowInvoke(activateContext, activator, intent);
      if (allowInvoke) {
        Actions.maybeInvoke(activateContext, intent);
      }
    }
  }

  /// Resolve target context for given [intent]
  BuildContext? _resolveInvokeContext(Intent intent) {
    // Same lookup as [ShortcutManager.handleKeypress]
    final focusedContext = primaryFocus?.context;
    // Allow previous/next to use parent context when focusContext is null
    // to allow user to focus something even when there is no autofocus.
    return focusedContext ??
        ((intent is PreviousFocusIntent || intent is NextFocusIntent)
            ? context
            : null);
  }

  /// Check if invoking [intent] is permitted by
  /// CallbackInterceptor.onBeforeInvoke and onBeforeInvoke.
  bool _allowInvoke(BuildContext activateContext, GamepadActivator activator, Intent intent) {
    final interceptor = activateContext
        .findAncestorWidgetOfExactType<GamepadInterceptor>();
    var allow = true;
    if (interceptor != null) {
      allow = interceptor.onBeforeIntent(activator, intent);
    }
    if (allow && widget.onBeforeIntent != null) {
      allow = widget.onBeforeIntent!(activator, intent);
    }
    return allow;
  }

  void _onRepeat(GamepadActivator activator, Intent intent) {
    _maybeInvokeIntent(activator, intent, const Duration(milliseconds: 200));
  }

  void _updatePreviousAxisValues(NormalizedGamepadEvent event) {
    if (event.axis != null) {
      _previousAxisValue[event.axis!] = event.value;
    }
  }
}
