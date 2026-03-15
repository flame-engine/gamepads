import 'package:gamepads_platform_interface/api/gamepad_axis.dart';
import 'package:gamepads_platform_interface/api/gamepad_button.dart';
import 'package:gamepads_platform_interface/src/mappings/controller_db.dart';

/// Parses SDL GameController DB format mapping strings into
/// [ControllerMapping] objects.
///
/// The SDL format is:
/// ```
/// GUID,name,a:b0,b:b1,...,platform:Linux,
/// ```
///
/// Where:
/// - GUID is a 32-char hex string encoding bus type, VID, PID, etc.
/// - Buttons: `a:b0` maps SDL button name to hardware button index
/// - Axes: `leftx:a0` maps SDL axis name to hardware axis index
/// - Hats: `dpup:h0.1` maps d-pad to hat index and bitmask
/// - Platform: `platform:Linux` or `platform:Windows`
///
/// The GUID encodes vendor/product IDs at specific byte offsets:
/// - Bytes 4-5 (hex chars 8-11): Vendor ID (little-endian)
/// - Bytes 8-9 (hex chars 16-19): Product ID (little-endian)
class SdlMappingParser {
  SdlMappingParser._();

  /// SDL button name to [GamepadButton] mapping.
  static const _sdlButtonNames = <String, GamepadButton>{
    'a': GamepadButton.a,
    'b': GamepadButton.b,
    'x': GamepadButton.x,
    'y': GamepadButton.y,
    'leftshoulder': GamepadButton.leftBumper,
    'rightshoulder': GamepadButton.rightBumper,
    'lefttrigger': GamepadButton.leftTrigger,
    'righttrigger': GamepadButton.rightTrigger,
    'back': GamepadButton.back,
    'start': GamepadButton.start,
    'guide': GamepadButton.home,
    'leftstick': GamepadButton.leftStick,
    'rightstick': GamepadButton.rightStick,
    'dpup': GamepadButton.dpadUp,
    'dpdown': GamepadButton.dpadDown,
    'dpleft': GamepadButton.dpadLeft,
    'dpright': GamepadButton.dpadRight,
  };

  /// SDL axis name to [GamepadAxis] mapping.
  static const _sdlAxisNames = <String, GamepadAxis>{
    'leftx': GamepadAxis.leftStickX,
    'lefty': GamepadAxis.leftStickY,
    'rightx': GamepadAxis.rightStickX,
    'righty': GamepadAxis.rightStickY,
    'lefttrigger': GamepadAxis.leftTrigger,
    'righttrigger': GamepadAxis.rightTrigger,
  };

  /// D-pad button names for hat-to-dpad-axis conversion.
  static const _dpadButtons = {
    'dpup',
    'dpdown',
    'dpleft',
    'dpright',
  };

  /// Extracts vendor ID from an SDL GUID string.
  ///
  /// The VID is stored at bytes 4-5 (hex chars 8-11) in little-endian.
  static int? extractVendorId(String guid) {
    if (guid.length < 12) {
      return null;
    }
    return _parseLittleEndianUint16(guid.substring(8, 12));
  }

  /// Extracts product ID from an SDL GUID string.
  ///
  /// The PID is stored at bytes 8-9 (hex chars 16-19) in little-endian.
  static int? extractProductId(String guid) {
    if (guid.length < 20) {
      return null;
    }
    return _parseLittleEndianUint16(guid.substring(16, 20));
  }

  static int? _parseLittleEndianUint16(String hex) {
    if (hex.length != 4) {
      return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return null;
    }
    // Swap bytes: "5e04" → 0x045e
    final low = parsed >> 8;
    final high = (parsed & 0xFF) << 8;
    return high | low;
  }

  /// Parses a single SDL mapping line into a [SdlParsedMapping].
  ///
  /// Returns `null` if the line is a comment, empty, or malformed.
  static SdlParsedMapping? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      return null;
    }

    final parts = trimmed.split(',');
    if (parts.length < 3) {
      return null;
    }

    final guid = parts[0];
    final name = parts[1];

    final vendorId = extractVendorId(guid);
    final productId = extractProductId(guid);
    if (vendorId == null || productId == null) {
      return null;
    }

    String? platform;
    final buttons = <String, GamepadButton>{};
    final axes = <String, GamepadAxis>{};
    final dpadAxes = <String, bool>{};
    var maxRegularAxisIndex = -1;
    final hatDpadEntries = <String, _HatEntry>{};

    for (var i = 2; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) {
        continue;
      }

      final colonIndex = part.indexOf(':');
      if (colonIndex < 0) {
        continue;
      }

      final sdlName = part.substring(0, colonIndex);
      final binding = part.substring(colonIndex + 1);

      if (sdlName == 'platform') {
        platform = binding;
        continue;
      }

      _parseBinding(
        sdlName: sdlName,
        binding: binding,
        buttons: buttons,
        axes: axes,
        hatDpadEntries: hatDpadEntries,
        maxRegularAxisIndex: maxRegularAxisIndex,
        onMaxAxisUpdate: (value) => maxRegularAxisIndex = value,
      );
    }

    // Convert hat-based d-pad entries to axis indices.
    // On Linux, hat N maps to axes (maxRegularAxis + 1 + 2*N) for X
    // and (maxRegularAxis + 2 + 2*N) for Y.
    _convertHatsToDpadAxes(
      hatDpadEntries: hatDpadEntries,
      dpadAxes: dpadAxes,
      maxRegularAxisIndex: maxRegularAxisIndex,
    );

    return SdlParsedMapping(
      guid: guid,
      name: name,
      vendorId: vendorId,
      productId: productId,
      platform: platform,
      mapping: ControllerMapping(
        buttons: buttons,
        axes: axes,
        dpadAxes: dpadAxes,
        yAxisInverted: true,
        stickRange: (-32768, 32767),
        triggerRange: (-32768, 32767),
      ),
    );
  }

  static void _parseBinding({
    required String sdlName,
    required String binding,
    required Map<String, GamepadButton> buttons,
    required Map<String, GamepadAxis> axes,
    required Map<String, _HatEntry> hatDpadEntries,
    required int maxRegularAxisIndex,
    required void Function(int) onMaxAxisUpdate,
  }) {
    // Button binding: "b0", "b1", etc.
    if (binding.startsWith('b')) {
      final index = int.tryParse(binding.substring(1));
      if (index == null) {
        return;
      }

      // Check if this is a button mapped to a standard button.
      final button = _sdlButtonNames[sdlName];
      if (button != null) {
        buttons[index.toString()] = button;
      }
      return;
    }

    // Axis binding: "a0", "a1", "+a0", "-a0", "a0~", etc.
    if (binding.startsWith('a') ||
        binding.startsWith('+a') ||
        binding.startsWith('-a')) {
      var axisStr = binding;
      // Strip modifiers for index extraction.
      final inverted = axisStr.endsWith('~');
      if (inverted) {
        axisStr = axisStr.substring(0, axisStr.length - 1);
      }
      if (axisStr.startsWith('+') || axisStr.startsWith('-')) {
        axisStr = axisStr.substring(1);
      }
      if (axisStr.startsWith('a')) {
        axisStr = axisStr.substring(1);
      }

      final index = int.tryParse(axisStr);
      if (index == null) {
        return;
      }

      // Track highest regular axis index for hat offset calculation.
      if (index > maxRegularAxisIndex) {
        onMaxAxisUpdate(index);
      }

      // Check if this SDL name maps to a standard axis.
      final axis = _sdlAxisNames[sdlName];
      if (axis != null) {
        axes[index.toString()] = axis;
        return;
      }

      // D-pad mapped to axis (rare but possible).
      if (_dpadButtons.contains(sdlName)) {
        final button = _sdlButtonNames[sdlName];
        if (button != null) {
          buttons[index.toString()] = button;
        }
      }
      return;
    }

    // Hat binding: "h0.1", "h0.2", "h0.4", "h0.8"
    if (binding.startsWith('h')) {
      final dotIndex = binding.indexOf('.');
      if (dotIndex < 0) {
        return;
      }

      final hatIndex = int.tryParse(binding.substring(1, dotIndex));
      final hatMask = int.tryParse(binding.substring(dotIndex + 1));
      if (hatIndex == null || hatMask == null) {
        return;
      }

      if (_dpadButtons.contains(sdlName)) {
        hatDpadEntries[sdlName] = _HatEntry(hatIndex, hatMask);
      }
    }
  }

  static void _convertHatsToDpadAxes({
    required Map<String, _HatEntry> hatDpadEntries,
    required Map<String, bool> dpadAxes,
    required int maxRegularAxisIndex,
  }) {
    if (hatDpadEntries.isEmpty) {
      return;
    }

    // Find the hat indices used for d-pad.
    final hatIndices = hatDpadEntries.values.map(
      (entry) => entry.hatIndex,
    ).toSet();

    for (final hatIndex in hatIndices) {
      // On Linux js API, hat N maps to axes:
      // X axis = maxRegularAxisIndex + 1 + 2 * hatIndex
      // Y axis = maxRegularAxisIndex + 2 + 2 * hatIndex
      final xAxisIndex = maxRegularAxisIndex + 1 + 2 * hatIndex;
      final yAxisIndex = maxRegularAxisIndex + 2 + 2 * hatIndex;
      dpadAxes[xAxisIndex.toString()] = true;
      dpadAxes[yAxisIndex.toString()] = false;
    }
  }

  /// Parses multiple SDL mapping lines and returns all valid mappings.
  ///
  /// Optionally filters by [platform] (e.g., "Linux", "Windows").
  static List<SdlParsedMapping> parseLines(
    String content, {
    String? platform,
  }) {
    final results = <SdlParsedMapping>[];
    for (final line in content.split('\n')) {
      final parsed = parseLine(line);
      if (parsed == null) {
        continue;
      }
      if (platform != null && parsed.platform != platform) {
        continue;
      }
      results.add(parsed);
    }
    return results;
  }

  /// Parses SDL mapping lines directly into a VID/PID-keyed map,
  /// avoiding intermediate list allocation.
  ///
  /// If multiple entries exist for the same VID/PID, the last one wins.
  static Map<(int, int), ControllerMapping> parseToDb(
    String content, {
    String? platform,
  }) {
    final database = <(int, int), ControllerMapping>{};
    for (final line in content.split('\n')) {
      final parsed = parseLine(line);
      if (parsed == null) {
        continue;
      }
      if (platform != null && parsed.platform != platform) {
        continue;
      }
      database[(parsed.vendorId, parsed.productId)] = parsed.mapping;
    }
    return database;
  }
}

/// A parsed SDL mapping line with extracted metadata.
class SdlParsedMapping {
  final String guid;
  final String name;
  final int vendorId;
  final int productId;
  final String? platform;
  final ControllerMapping mapping;

  const SdlParsedMapping({
    required this.guid,
    required this.name,
    required this.vendorId,
    required this.productId,
    required this.platform,
    required this.mapping,
  });
}

class _HatEntry {
  final int hatIndex;
  final int hatMask;

  const _HatEntry(this.hatIndex, this.hatMask);
}
