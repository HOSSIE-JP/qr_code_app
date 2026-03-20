import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/app_prefs.dart';

/// アプリケーションのエントリーポイント。
///
/// [ProviderScope] で Riverpod のスコープを構成し、
/// [App] ウィジェットをルートとして起動する。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();
  runApp(const ProviderScope(child: App()));
}
