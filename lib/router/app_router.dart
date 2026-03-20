import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../features/detail/detail_page.dart';
import '../features/detail/edit_page.dart';
import '../features/export_import/export_page.dart';
import '../features/export_import/import_page.dart';
import '../features/generator/generator_page.dart';
import '../features/home/home_page.dart';
import '../features/scanner/scanner_page.dart';
import '../features/scanner/scan_progress_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../features/thumbnail/thumbnail_crop_page.dart';
import '../features/viewer/qr_viewer_page.dart';

part 'app_router.gr.dart';

/// アプリ全体のルート定義。
///
/// auto_route による型安全な画面遷移を提供する。
/// それぞれのルートは対応するページ Widget にマッピングされる。
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: ScannerRoute.page),
    AutoRoute(page: ScanProgressRoute.page),
    AutoRoute(page: GeneratorRoute.page),
    AutoRoute(page: DetailRoute.page),
    AutoRoute(page: EditRoute.page),
    AutoRoute(page: QrViewerRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: ExportRoute.page),
    AutoRoute(page: ImportRoute.page),
    AutoRoute(page: ThumbnailCropRoute.page),
    AutoRoute(page: SettingsRoute.page),
  ];
}
