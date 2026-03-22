import 'cloud_backup_service.dart';

/// OneDrive 認証のプラットフォーム依存処理を抽象化する。
abstract class OneDriveAuthClient {
  /// 対話認証でアクセストークンを取得する。
  Future<OneDriveTokenBundle> acquireTokenInteractively({
    required String clientId,
    required String authority,
    required List<String> scopes,
  });

  /// ネイティブキャッシュからアクセストークンを復元する。
  Future<OneDriveTokenBundle?> acquireTokenSilently({
    required String clientId,
    required String authority,
    required List<String> scopes,
  });

  /// ネイティブ側の認証セッションを破棄する。
  Future<void> signOut();
}
