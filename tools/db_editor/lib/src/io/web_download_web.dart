import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// ブラウザで指定バイト列のダウンロードを開始する。
void downloadBytesOnWeb({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  final encoded = base64Encode(bytes);
  final href = 'data:$mimeType;base64,$encoded';

  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = fileName;

  anchor.click();
}
