import 'package:shared_preferences/shared_preferences.dart';

/// アプリ内で利用する永続設定キー。
abstract final class AppPrefKeys {
  static const String currentDatabaseId = 'current_database_id';
  static const String sortField = 'sort_field';
  static const String sortAscending = 'sort_ascending';
  static const String homeGridView = 'home_grid_view';
  static const String qrViewerDefaultSize = 'qr_viewer_default_size';
  static const String qrGenerationErrorLevel = 'qr_generation_error_level';
  static const String qrGenerationGapless = 'qr_generation_gapless';
  static const String qrGenerationPadding = 'qr_generation_padding';
}

/// SharedPreferences を通じた簡易永続設定アクセス。
///
/// `main()` 起動時に [init] を必ず呼び出してから利用する。
final class AppPrefs {
  AppPrefs._();

  static SharedPreferences? _prefs;

  static SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('AppPrefs.init() が呼ばれていません。');
    }
    return prefs;
  }

  /// SharedPreferences を初期化する。
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 初期化済みかどうか。
  static bool get isInitialized => _prefs != null;

  static String? get currentDatabaseId =>
      _instance.getString(AppPrefKeys.currentDatabaseId);
  static Future<void> setCurrentDatabaseId(String value) =>
      _instance.setString(AppPrefKeys.currentDatabaseId, value);

  static String? get sortField => _instance.getString(AppPrefKeys.sortField);
  static Future<void> setSortField(String value) =>
      _instance.setString(AppPrefKeys.sortField, value);

  static bool? get sortAscending =>
      _instance.getBool(AppPrefKeys.sortAscending);
  static Future<void> setSortAscending(bool value) =>
      _instance.setBool(AppPrefKeys.sortAscending, value);

  static bool get homeGridView =>
      _instance.getBool(AppPrefKeys.homeGridView) ?? true;
  static Future<void> setHomeGridView(bool value) =>
      _instance.setBool(AppPrefKeys.homeGridView, value);

  static double get qrViewerDefaultSize =>
      _instance.getDouble(AppPrefKeys.qrViewerDefaultSize) ?? 300;
  static Future<void> setQrViewerDefaultSize(double value) =>
      _instance.setDouble(AppPrefKeys.qrViewerDefaultSize, value);

  static String get qrGenerationErrorLevel =>
      _instance.getString(AppPrefKeys.qrGenerationErrorLevel) ?? 'medium';
  static Future<void> setQrGenerationErrorLevel(String value) =>
      _instance.setString(AppPrefKeys.qrGenerationErrorLevel, value);

  static bool get qrGenerationGapless =>
      _instance.getBool(AppPrefKeys.qrGenerationGapless) ?? false;
  static Future<void> setQrGenerationGapless(bool value) =>
      _instance.setBool(AppPrefKeys.qrGenerationGapless, value);

  static double get qrGenerationPadding =>
      _instance.getDouble(AppPrefKeys.qrGenerationPadding) ?? 16;
  static Future<void> setQrGenerationPadding(double value) =>
      _instance.setDouble(AppPrefKeys.qrGenerationPadding, value);
}
