import 'cloud_backup_service.dart';
import 'onedrive_auth_client.dart';

/// IO 非対応プラットフォーム向けのダミー実装を返す。
OneDriveAuthClient createOneDriveAuthClient() =>
    _UnsupportedOneDriveAuthClient();

class _UnsupportedOneDriveAuthClient implements OneDriveAuthClient {
  @override
  Future<OneDriveTokenBundle> acquireTokenInteractively({
    required String clientId,
    required String authority,
    required List<String> scopes,
  }) async {
    throw StateError('OneDrive はこのプラットフォームで利用できません。');
  }

  @override
  Future<OneDriveTokenBundle?> acquireTokenSilently({
    required String clientId,
    required String authority,
    required List<String> scopes,
  }) async {
    return null;
  }

  @override
  Future<void> signOut() async {}
}
