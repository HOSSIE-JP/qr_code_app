/// アプリ全体で使用する定数を集約するクラス。
///
/// サムネイルサイズ、データサイズ上限、エクスポート関連の識別子を定義する。
abstract final class AppConstants {
  /// QR Version 40 / ECC-L で格納可能な最大バイト数。
  static const int qrMaxTextBytes = 2953;

  /// サムネイル画像の最大幅（ピクセル）。アスペクト比は維持される。
  static const int thumbnailMaxWidth = 512;

  /// エクスポートファイルの拡張子（ZIP 形式）。
  static const String exportFileExtension = '.qrdb';

  /// エクスポートファイルの拡張子（JSON 形式）。
  static const String exportJsonExtension = '.qrjson';

  /// エクスポートファイルの MIME タイプ。
  static const String exportMimeType = 'application/zip';
}
