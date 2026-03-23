import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> shareLog(List<String> log) async {
  final bytes = Uint8List.fromList(utf8.encode(log.join('\n')));
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/plain'),
  );
  final url = web.URL.createObjectURL(blob);
  (web.HTMLAnchorElement()
        ..href = url
        ..download = 'gamepad_log.txt')
      .click();
  web.URL.revokeObjectURL(url);
}
