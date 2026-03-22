import 'package:flutter/foundation.dart';
import 'package:msal_auth/msal_auth.dart';

import 'cloud_backup_service.dart';
import 'onedrive_auth_client.dart';

/// MSAL ベースの OneDrive 認証クライアントを返す。
OneDriveAuthClient createOneDriveAuthClient() => _MsalOneDriveAuthClient();

/// サイレント認証失敗時に対話認証へフォールバックすべき MSAL 例外かを返す。
@visibleForTesting
bool isMsalInteractiveLoginRequired(Exception error) {
  final typeName = error.runtimeType.toString();
  final message = _describeMsalError(error).toLowerCase();
  return error is MsalUiRequiredException ||
      typeName == 'MsalUiRequiredException' ||
      message.contains('ui required') ||
      message.contains('no account') ||
      message.contains('no signed in account') ||
      message.contains('no currently signed in account');
}

/// アカウント未保持として無視してよい MSAL 例外かを返す。
@visibleForTesting
bool canIgnoreMissingMsalAccount(Exception error) {
  final message = _describeMsalError(error).toLowerCase();
  return message.contains('no account') ||
      message.contains('no signed in account') ||
      message.contains('no currently signed in account');
}

/// ユーザーキャンセルとして扱うべき MSAL 例外かを返す。
@visibleForTesting
bool isMsalUserCancellation(Exception error) {
  final typeName = error.runtimeType.toString();
  final normalized = _describeMsalError(error).toLowerCase();
  return error is MsalUserCancelException ||
      typeName == 'MsalUserCancelException' ||
      normalized.contains('cancel') ||
      normalized.contains('user cancelled');
}

/// プラットフォームに応じた MSAL の対話認証 prompt を返す。
@visibleForTesting
Prompt resolveMsalPrompt(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
      // 個人 Microsoft アカウント専用では、端末側の組織アカウント候補に
      // 引っ張られにくいよう資格情報入力画面を優先する。
      return Prompt.login;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return Prompt.selectAccount;
  }
}

String _describeMsalError(Exception error) {
  final message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message;
}

class _MsalOneDriveAuthClient implements OneDriveAuthClient {
  static const String _androidConfigFilePath = 'assets/msal_config.json';
  static const String _androidRedirectUri =
      'msauth://jp.co.geroneko/zzvXMUAcU3YjMd0QbTOeRb7g8dY%3D';

  SingleAccountPca? _publicClientApplication;
  Future<SingleAccountPca>? _creatingApplication;

  @override
  Future<OneDriveTokenBundle> acquireTokenInteractively({
    required String clientId,
    required String authority,
    required List<String> scopes,
  }) async {
    try {
      final publicClientApplication = await _getPublicClientApplication(
        clientId: clientId,
        authority: authority,
      );
      final result = await publicClientApplication.acquireToken(
        scopes: scopes,
        authority: authority,
        prompt: resolveMsalPrompt(defaultTargetPlatform),
      );
      return _toTokenBundle(result);
    } on Exception catch (error) {
      final message = _describeMsalError(error);
      if (isMsalUserCancellation(error)) {
        throw StateError('OneDrive 認証がキャンセルされました。');
      }
      throw StateError('OneDrive 認証に失敗しました: $message');
    }
  }

  @override
  Future<OneDriveTokenBundle?> acquireTokenSilently({
    required String clientId,
    required String authority,
    required List<String> scopes,
  }) async {
    try {
      final publicClientApplication = await _getPublicClientApplication(
        clientId: clientId,
        authority: authority,
      );
      final result = await publicClientApplication.acquireTokenSilent(
        scopes: scopes,
        authority: authority,
      );
      return _toTokenBundle(result);
    } on Exception catch (error) {
      if (isMsalInteractiveLoginRequired(error)) {
        return null;
      }
      throw StateError('OneDrive 認証状態の復元に失敗しました: ${_describeMsalError(error)}');
    }
  }

  @override
  Future<void> signOut() async {
    final publicClientApplication = _publicClientApplication;
    if (publicClientApplication == null) {
      return;
    }

    try {
      await publicClientApplication.signOut();
    } on Exception catch (error) {
      if (canIgnoreMissingMsalAccount(error)) {
        return;
      }
      throw StateError('OneDrive のサインアウトに失敗しました: ${_describeMsalError(error)}');
    }
  }

  Future<SingleAccountPca> _getPublicClientApplication({
    required String clientId,
    required String authority,
  }) async {
    final existing = _publicClientApplication;
    if (existing != null) {
      return existing;
    }

    final pending = _creatingApplication;
    if (pending != null) {
      return pending;
    }

    final creation = SingleAccountPca.create(
      clientId: clientId,
      androidConfig: _buildAndroidConfig(),
      appleConfig: _buildAppleConfig(authority),
    );
    _creatingApplication = creation;

    try {
      final created = await creation;
      _publicClientApplication = created;
      return created;
    } finally {
      _creatingApplication = null;
    }
  }

  AndroidConfig? _buildAndroidConfig() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    return AndroidConfig(
      configFilePath: _androidConfigFilePath,
      redirectUri: _androidRedirectUri,
    );
  }

  AppleConfig? _buildAppleConfig(String authority) {
    if (kIsWeb) {
      return null;
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
      return null;
    }

    return AppleConfig(authority: authority);
  }

  OneDriveTokenBundle _toTokenBundle(AuthenticationResult result) {
    return OneDriveTokenBundle(
      accessToken: result.accessToken,
      expiresAt: result.expiresOn,
    );
  }
}
