import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';

class SliderWithGamepadSupport extends StatelessWidget {
  final int divisions;
  final double value;
  final String? label;
  final double min;
  final double max;
  final void Function(double) onChanged;

  const SliderWithGamepadSupport({
    required this.onChanged,
    required this.value,
    required this.divisions,
    this.min = 0,
    this.max = 1.0,
    this.label,
    super.key,
  });

  double get step => (max - min) / math.max(divisions, 1);

  @override
  Widget build(BuildContext context) {
    return GamepadInterceptor(
      onBeforeIntent: (activator, intent) {
        // The Slider widget does not itself support any public Intent to
        // control it.
        //
        // So instead we intercept that GamepadControl is about to emit a
        // ScrollIntent and implement changing the Slider value ourself.
        if (intent is ScrollIntent) {
          if (intent.direction == AxisDirection.right) {
            onChanged(math.min(max, value + step));
          } else if (intent.direction == AxisDirection.left) {
            onChanged(math.max(min, value - step));
          }
          return false;
        }
        return true;
      },
      child: Slider.adaptive(
        max: max,
        divisions: divisions,
        label: label,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
