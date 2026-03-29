import 'package:flutter/material.dart';

/// Wrap part of your widget tree with this widget to be able to
/// receive onBeforeIntent locally near the widget you want to control.
///
/// This has to wrap the widget that holds the FocusNode. Eg. to wrap
/// a Slider() or other control you want to setup gamepad support for.
class GamepadInterceptor extends StatelessWidget {
  final Widget child;
  final bool Function(Intent) onBeforeIntent;

  const GamepadInterceptor({
    /// Called just before an Intent is invoked. Return false to block
    /// emitting the Intent.
    required this.onBeforeIntent,

    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
