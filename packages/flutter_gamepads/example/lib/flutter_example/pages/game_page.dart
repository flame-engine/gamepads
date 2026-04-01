import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:gamepads/gamepads.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      backgroundColor: Colors.green[900],
      body: const _TickTackToe(),
    );
  }
}

class _TickTackToe extends StatefulWidget {
  const _TickTackToe();

  @override
  State<_TickTackToe> createState() => _TickTackToeState();
}

enum _CellValue {
  empty,
  o,
  x,
}

class _TickTackToeState extends State<_TickTackToe> {
  late final List<_CellValue> _board;
  late final List<FocusNode> _focusNodes;
  var _player = _CellValue.x;

  static const buttonDirMap = {
    GamepadButton.dpadUp: AxisDirection.up,
    GamepadButton.dpadDown: AxisDirection.down,
    GamepadButton.dpadLeft: AxisDirection.left,
    GamepadButton.dpadRight: AxisDirection.right,
  };

  @override
  void initState() {
    _board = List<_CellValue>.generate(9, (_) => _CellValue.empty);
    _focusNodes = List<FocusNode>.generate(9, (_) => FocusNode());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadInterceptor(
      onBeforeIntent: (activator, intent) {
        if (intent is ScrollIntent) {
          moveFocus(intent.direction);
          return false;
        }
        if (activator is GamepadActivatorButton &&
            buttonDirMap.keys.contains(activator.button)) {
          return !moveFocus(buttonDirMap[activator.button]!);
        }
        return true;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: _cellSize * 3,
              height: _cellSize * 3,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                children: _board
                    .mapIndexed(
                      (i, v) => _Cell(
                        onActivate: () => cellActivate(i),
                        value: v,
                        index: i,
                        focusNode: _focusNodes[i],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Current player: ${switch (_player) {
              _CellValue.x => 'x',
              _CellValue.o => 'o',
              _CellValue.empty => '',
            }}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(MediaQuery.sizeOf(context).width, 500),
              ),
              child: const Text(
                'GAMEPAD INFO\n'
                'You can use the D-pad or right stick to move focus directionally up/down/left/right'
                ' which is supported via GamepadInterceptor.'
                '\n\n'
                'Left stick only works while focus is within the 3x3 grid.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool moveFocus(AxisDirection direction) {
    final focusedIndex = _focusNodes.indexWhere(
      (focusNode) => focusNode.hasFocus,
    );
    var newFocusedIndex = focusedIndex;
    if (newFocusedIndex == -1) {
      newFocusedIndex = 4;
    } else {
      switch (direction) {
        case AxisDirection.down:
          if (newFocusedIndex < 6) {
            newFocusedIndex += 3;
          }
        case AxisDirection.up:
          if (newFocusedIndex > 2) {
            newFocusedIndex -= 3;
          }
        case AxisDirection.left:
          if (newFocusedIndex % 3 > 0) {
            newFocusedIndex -= 1;
          }
        case AxisDirection.right:
          if (newFocusedIndex % 3 < 2) {
            newFocusedIndex += 1;
          }
      }
    }
    if (newFocusedIndex != focusedIndex) {
      _focusNodes[newFocusedIndex].requestFocus();
      return true;
    }
    return false;
  }

  void cellActivate(int index) {
    setState(() {
      _board[index] = _player;
      _player = switch (_player) {
        _CellValue.o => _CellValue.x,
        _CellValue.x => _CellValue.o,
        _CellValue.empty => throw Exception(),
      };
    });
  }
}

class _Cell extends StatefulWidget {
  final void Function() onActivate;
  final _CellValue value;
  final int index;
  final FocusNode focusNode;
  const _Cell({
    required this.value,
    required this.index,
    required this.focusNode,
    required this.onActivate,
  });

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            fixedSize: const WidgetStatePropertyAll(
              Size(_cellSize, _cellSize),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(),
            ),
            backgroundColor: WidgetStatePropertyAll(Colors.brown[300]),
            side: WidgetStateProperty.resolveWith((state) {
              return BorderSide(
                color: state.contains(WidgetState.focused)
                    ? Colors.orange
                    : Colors.brown,
                width: 3,
              );
            }),
          ),
        ),
      ),
      child: FilledButton(
        focusNode: widget.focusNode,
        onPressed: () {
          widget.onActivate();
        },
        child: switch (widget.value) {
          _CellValue.empty => Container(),
          _CellValue.x => const Icon(Icons.close),
          _CellValue.o => const Icon(Icons.circle_outlined),
        },
      ),
    );
  }
}

const _cellSize = 70.0;
