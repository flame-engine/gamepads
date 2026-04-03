import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// A dialog backdrop that also moves Focus to within the dialog and blocks
/// pointer input outside of the dialog.
class OverlayDialogBackdrop extends StatefulWidget {
  final Widget child;
  const OverlayDialogBackdrop({required this.child, super.key});

  @override
  State<OverlayDialogBackdrop> createState() => _OverlayDialogBackdropState();
}

class _OverlayDialogBackdropState extends State<OverlayDialogBackdrop> {
  final FocusScopeNode _focusScope = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    // Set the focus within the dialog just after it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScope.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // A FocusScope widget traps the focus to stay within the dialog.
        // (but it doesn't itself move the focus there, hence the code in
        // initState)
        child: FocusScope(node: _focusScope, child: widget.child),
      ),
    );
  }
}
