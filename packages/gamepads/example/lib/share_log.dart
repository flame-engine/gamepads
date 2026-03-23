import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareLog(List<String> log) async {
  final bytes = Uint8List.fromList(utf8.encode(log.join('\n')));
  final xFile = XFile.fromData(
    bytes,
    name: 'gamepad_log.txt',
    mimeType: 'text/plain',
  );
  await Share.shareXFiles([xFile]);
}
