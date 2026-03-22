import 'dart:typed_data';

/// Web でのバイト列ダウンロードを抽象化する。
///
/// 非 Web ではこのメソッドを利用しない想定で、呼ばれた場合は例外を返す。
void downloadBytesOnWeb({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  throw UnsupportedError('downloadBytesOnWeb は Web でのみ利用できます。');
}
