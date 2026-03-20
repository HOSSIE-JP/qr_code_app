import 'dart:convert';
import 'dart:typed_data';

/// QR データのテキスト/バイナリ判定を扱うユーティリティ。
class QrDataTypeUtils {
  /// [data] が UTF-8 テキストとして妥当かどうかを判定する。
  ///
  /// - UTF-8 としてデコードできること
  /// - 0x00 などの制御文字を含まないこと
  /// - 印字可能文字の比率が十分に高いこと
  static bool isLikelyText(Uint8List data) {
    if (data.isEmpty) {
      return true;
    }

    String decoded;
    try {
      decoded = utf8.decode(data);
    } on FormatException {
      return false;
    }

    var printableCount = 0;
    final total = decoded.runes.length;
    if (total == 0) {
      return true;
    }

    for (final rune in decoded.runes) {
      if (_isAllowedControl(rune) || _isPrintable(rune)) {
        printableCount++;
      } else {
        return false;
      }
    }

    final printableRatio = printableCount / total;
    return printableRatio >= 0.95;
  }

  /// [isTextMode] の初期推定値を返す。
  static bool inferIsTextMode(Uint8List data) => isLikelyText(data);

  static bool _isAllowedControl(int rune) {
    return rune == 0x09 || rune == 0x0A || rune == 0x0D;
  }

  static bool _isPrintable(int rune) {
    // Unicode の一般的な可視文字を許容。
    return rune >= 0x20 && rune != 0x7F;
  }
}
