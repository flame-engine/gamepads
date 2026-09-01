import 'dart:js_interop';

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:web/web.dart';

List<GamepadController> getGamepads(GamepadsPlatformInterface plugin) {
  return getGamepadList().map(
    (gamepad) {
      final ids = parseGamepadIds(gamepad.id);
      return GamepadController(
        id: gamepad.index.toString(),
        name: gamepad.id,
        plugin: plugin,
        vendorId: ids.vendorId,
        productId: ids.productId,
      );
    },
  ).toList();
}

List<Gamepad> getGamepadList() {
  return window.navigator.getGamepads().toDart.whereType<Gamepad>().toList();
}

/// Parses vendor/product IDs from the Web Gamepad API id string.
///
/// Common formats:
/// - "Xbox 360 Controller (Vendor: 045e Product: 028e)"
/// - "045e-028e-Xbox 360 Controller"
({int? vendorId, int? productId}) parseGamepadIds(String id) {
  // Try "Vendor: XXXX Product: XXXX" format
  final vendorMatch = RegExp(r'Vendor:\s*([0-9a-fA-F]{4})').firstMatch(id);
  final productMatch = RegExp(r'Product:\s*([0-9a-fA-F]{4})').firstMatch(id);
  if (vendorMatch != null && productMatch != null) {
    return (
      vendorId: int.parse(vendorMatch.group(1)!, radix: 16),
      productId: int.parse(productMatch.group(1)!, radix: 16),
    );
  }

  // Try "XXXX-XXXX-Name" format
  final dashMatch = RegExp(
    '^([0-9a-fA-F]{4})-([0-9a-fA-F]{4})',
  ).firstMatch(id);
  if (dashMatch != null) {
    return (
      vendorId: int.parse(dashMatch.group(1)!, radix: 16),
      productId: int.parse(dashMatch.group(2)!, radix: 16),
    );
  }

  return (vendorId: null, productId: null);
}
