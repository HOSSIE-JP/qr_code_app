import 'onedrive_auth_client.dart';
import 'onedrive_auth_client_factory_stub.dart'
    if (dart.library.io) 'onedrive_auth_client_factory_msal.dart';

/// 実行プラットフォームに応じた OneDrive 認証クライアントを生成する。
OneDriveAuthClient createDefaultOneDriveAuthClient() {
  return createOneDriveAuthClient();
}
