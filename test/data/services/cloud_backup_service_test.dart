import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_code_app/data/services/cloud_backup_service.dart';
import 'package:qr_code_app/data/services/onedrive_auth_client.dart';

class _InMemoryTokenStore implements OneDriveTokenStore {
  _InMemoryTokenStore(this._token);

  OneDriveTokenBundle? _token;

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<OneDriveTokenBundle?> readToken() async => _token;

  @override
  Future<void> writeToken(OneDriveTokenBundle token) async {
    _token = token;
  }
}

class _FakeOneDriveAuthClient implements OneDriveAuthClient {
  _FakeOneDriveAuthClient({this.silentToken, this.interactiveToken});

  final OneDriveTokenBundle? silentToken;
  final OneDriveTokenBundle? interactiveToken;

  int silentCallCount = 0;
  int interactiveCallCount = 0;
  String? lastSilentClientId;
  String? lastSilentAuthority;
  List<String>? lastSilentScopes;
  String? lastInteractiveClientId;
  String? lastInteractiveAuthority;
  List<String>? lastInteractiveScopes;

  @override
  Future<OneDriveTokenBundle> acquireTokenInteractively({
    required String clientId,
    required String authority,
    required List<String> scopes,
  }) async {
    interactiveCallCount += 1;
    lastInteractiveClientId = clientId;
    lastInteractiveAuthority = authority;
    lastInteractiveScopes = List<String>.of(scopes);
    if (interactiveToken == null) {
      throw StateError('interactive token missing');
    }
    return interactiveToken!;
  }

  @override
  Future<OneDriveTokenBundle?> acquireTokenSilently({
    required String clientId,
    required String authority,
    required List<String> scopes,
  }) async {
    silentCallCount += 1;
    lastSilentClientId = clientId;
    lastSilentAuthority = authority;
    lastSilentScopes = List<String>.of(scopes);
    return silentToken;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OneDrive 初回 404 時はアプリフォルダ初期化後に再試行できる', () async {
    var approotCalls = 0;
    var uploadCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/special/approot')) {
        approotCalls += 1;
        return http.Response(
          jsonEncode(<String, Object>{
            'id': 'approot-1',
            'webUrl': 'https://example.invalid/drive/apps/sample-app',
          }),
          200,
        );
      }

      if (request.url.path.contains('approot:/backup.qrdb:/content')) {
        uploadCalls += 1;
        if (uploadCalls == 1) {
          return http.Response('not found', 404);
        }
        return http.Response('', 201);
      }

      return http.Response('not found', 404);
    });

    final service = CloudBackupService(
      httpClient: client,
      tokenStore: _InMemoryTokenStore(
        OneDriveTokenBundle(
          accessToken: 'test-access-token',
          expiresAt: DateTime(2099, 1, 1),
        ),
      ),
    );

    await service.uploadBackup(
      provider: CloudStorageProvider.oneDrive,
      fileName: 'backup.qrdb',
      bytes: Uint8List.fromList(const <int>[1, 2, 3]),
      mimeType: 'application/zip',
    );

    expect(approotCalls, 2);
    expect(uploadCalls, 2);
  });

  test('OneDrive一覧取得時にCloudBackupFileへ変換できる', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/special/approot')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'id': 'approot-1',
            'webUrl': 'https://example.invalid/drive/apps/sample-app',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/children')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Object>[
              <String, Object>{
                'id': 'one-1',
                'name': 'backup.qrdb',
                'size': 2048,
                'lastModifiedDateTime': DateTime(2026, 3, 21).toIso8601String(),
                'file': <String, Object>{'mimeType': 'application/zip'},
              },
            ],
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final service = CloudBackupService(
      httpClient: client,
      tokenStore: _InMemoryTokenStore(
        OneDriveTokenBundle(
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          expiresAt: DateTime(2099, 1, 1),
        ),
      ),
    );
    final files = await service.listBackups(
      provider: CloudStorageProvider.oneDrive,
    );

    expect(files, hasLength(1));
    expect(files.single.id, 'one-1');
    expect(files.single.name, 'backup.qrdb');
    expect(files.single.size, 2048);
  });

  test('OneDriveダウンロードでバイト列を取得できる', () async {
    final client = MockClient((request) async {
      if (request.url.path.contains('/content')) {
        return http.Response.bytes(const <int>[1, 2, 3, 4], 200);
      }
      return http.Response('not found', 404);
    });

    final service = CloudBackupService(
      httpClient: client,
      tokenStore: _InMemoryTokenStore(
        OneDriveTokenBundle(
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          expiresAt: DateTime(2099, 1, 1),
        ),
      ),
    );
    final bytes = await service.downloadBackup(
      provider: CloudStorageProvider.oneDrive,
      fileId: 'one-1',
    );

    expect(bytes, Uint8List.fromList(const <int>[1, 2, 3, 4]));
  });

  test('OneDriveダウンロードを一時ファイルへストリーム保存できる', () async {
    final client = MockClient((request) async {
      if (request.url.path.contains('/content')) {
        return http.Response.bytes(const <int>[9, 8, 7, 6], 200);
      }
      return http.Response('not found', 404);
    });

    final service = CloudBackupService(
      httpClient: client,
      tokenStore: _InMemoryTokenStore(
        OneDriveTokenBundle(
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          expiresAt: DateTime(2099, 1, 1),
        ),
      ),
    );
    final path = await service.downloadBackupToTemporaryFile(
      provider: CloudStorageProvider.oneDrive,
      fileId: 'one-1',
      suggestedFileName: 'cloud_backup.qrdb',
    );
    addTearDown(() async {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    });

    final bytes = await File(path).readAsBytes();
    expect(bytes, Uint8List.fromList(const <int>[9, 8, 7, 6]));
  });

  test('クラウド機能のプラットフォーム対応判定が正しい', () {
    final service = CloudBackupService();

    expect(
      service.isProviderSupported(
        CloudStorageProvider.oneDrive,
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      isTrue,
    );
    expect(
      service.isProviderSupported(
        CloudStorageProvider.oneDrive,
        platform: TargetPlatform.android,
        isWeb: true,
      ),
      isFalse,
    );
    expect(
      service.isProviderSupported(
        CloudStorageProvider.oneDrive,
        platform: TargetPlatform.windows,
        isWeb: false,
      ),
      isFalse,
    );
  });

  test('期限切れトークン時にMSALサイレント更新で一覧取得を継続できる', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/special/approot')) {
        expect(
          request.headers['Authorization'],
          'Bearer refreshed-access-token',
        );
        return http.Response(
          jsonEncode(<String, Object>{
            'id': 'approot-1',
            'webUrl': 'https://example.invalid/drive/apps/sample-app',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/children')) {
        expect(
          request.headers['Authorization'],
          'Bearer refreshed-access-token',
        );
        return http.Response(
          jsonEncode(<String, Object>{'value': <Object>[]}),
          200,
        );
      }
      return http.Response('not found', 404);
    });
    final authClient = _FakeOneDriveAuthClient(
      silentToken: OneDriveTokenBundle(
        accessToken: 'refreshed-access-token',
        expiresAt: DateTime(2099, 1, 1),
      ),
    );
    final tokenStore = _InMemoryTokenStore(
      OneDriveTokenBundle(
        accessToken: 'expired-access-token',
        expiresAt: DateTime(2000, 1, 1),
      ),
    );

    final service = CloudBackupService(
      authClient: authClient,
      httpClient: client,
      tokenStore: tokenStore,
      oneDriveClientId: 'test-client-id',
    );

    final files = await service.listBackups(
      provider: CloudStorageProvider.oneDrive,
    );

    expect(files, isEmpty);
    expect(authClient.silentCallCount, 1);
    expect(authClient.interactiveCallCount, 0);
    expect(authClient.lastSilentClientId, 'test-client-id');
    expect(
      authClient.lastSilentAuthority,
      'https://login.microsoftonline.com/consumers',
    );
    expect(authClient.lastSilentScopes, const <String>[
      'Files.ReadWrite.AppFolder',
    ]);
    expect(
      (await tokenStore.readToken())?.accessToken,
      'refreshed-access-token',
    );
  });

  test('認証要求時にMSAL対話認証でトークンを保存できる', () async {
    final authClient = _FakeOneDriveAuthClient(
      interactiveToken: OneDriveTokenBundle(
        accessToken: 'interactive-access-token',
        expiresAt: DateTime(2099, 1, 1),
      ),
    );
    final tokenStore = _InMemoryTokenStore(null);
    final service = CloudBackupService(
      authClient: authClient,
      tokenStore: tokenStore,
      oneDriveClientId: 'test-client-id',
    );

    await service.ensureOneDriveAuthentication();

    expect(authClient.silentCallCount, 1);
    expect(authClient.interactiveCallCount, 1);
    expect(authClient.lastSilentClientId, 'test-client-id');
    expect(
      authClient.lastSilentAuthority,
      'https://login.microsoftonline.com/consumers',
    );
    expect(authClient.lastSilentScopes, const <String>[
      'Files.ReadWrite.AppFolder',
    ]);
    expect(authClient.lastInteractiveClientId, 'test-client-id');
    expect(
      authClient.lastInteractiveAuthority,
      'https://login.microsoftonline.com/consumers',
    );
    expect(authClient.lastInteractiveScopes, const <String>[
      'Files.ReadWrite.AppFolder',
    ]);
    expect(
      (await tokenStore.readToken())?.accessToken,
      'interactive-access-token',
    );
  });
}
