import 'dart:io';

import 'package:flutter/foundation.dart';

/// 現在のプラットフォームがカメラベースの QR スキャンに対応しているかを返す。
///
/// Android, iOS, macOS, Web では true。Windows / Linux では false。
bool get isCameraScanSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}
