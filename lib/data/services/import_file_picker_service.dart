import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Import 画面用のファイル選択サービス。
class ImportFilePickerService {
  /// ファイル選択ダイアログを開く。
  Future<FilePickerResult?> pickImportFile() {
    return FilePicker.platform.pickFiles(type: FileType.any, withData: kIsWeb);
  }
}
