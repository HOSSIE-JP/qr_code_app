import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'onedrive_auth_client.dart';
import 'onedrive_auth_client_factory.dart';

/// クラウドバックアップの保存先種別。
enum CloudStorageProvider { oneDrive }

/// クラウド上のバックアップファイル情報。
class CloudBackupFile {
  /// クラウド上のファイルメタデータを生成する。
  const CloudBackupFile({
    required this.id,
    required this.name,
    required this.modifiedAt,
    required this.size,
    required this.mimeType,
  });

  /// クラウドストレージ上のファイル ID。
  final String id;

  /// 表示用のファイル名。
  final String name;

  /// 最終更新日時。
  final DateTime modifiedAt;

  /// ファイルサイズ。
  final int size;

  /// MIME Type。
  final String mimeType;
}

/// OneDrive のアクセストークンとリフレッシュトークンを保持する。
class OneDriveTokenBundle {
  /// トークン情報を生成する。
  const OneDriveTokenBundle({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });

  /// Graph API 呼び出しに使うアクセストークン。
  final String accessToken;

  /// アクセストークンの有効期限。
  final DateTime expiresAt;

  /// 更新用のリフレッシュトークン。
  final String? refreshToken;

  /// 期限切れ直前も更新対象として扱う。
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 2)));
}

/// OneDrive のトークン保管先抽象。
abstract class OneDriveTokenStore {
  /// 保存済みトークンを読み込む。
  Future<OneDriveTokenBundle?> readToken();

  /// トークンを保存する。
  Future<void> writeToken(OneDriveTokenBundle token);

  /// 保存済みトークンを削除する。
  Future<void> clearToken();
}

/// Secure Storage を用いた OneDrive トークン保管。
class SecureOneDriveTokenStore implements OneDriveTokenStore {
  /// Secure Storage ベースのトークンストアを生成する。
  SecureOneDriveTokenStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'onedrive_access_token';
  static const String _refreshTokenKey = 'onedrive_refresh_token';
  static const String _expiresAtKey = 'onedrive_expires_at';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<OneDriveTokenBundle?> readToken() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final expiresAtRaw = await _secureStorage.read(key: _expiresAtKey);
    if (accessToken == null || accessToken.isEmpty || expiresAtRaw == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      await clearToken();
      return null;
    }

    return OneDriveTokenBundle(
      accessToken: accessToken,
      refreshToken: await _secureStorage.read(key: _refreshTokenKey),
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> writeToken(OneDriveTokenBundle token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token.accessToken);
    await _secureStorage.write(
      key: _expiresAtKey,
      value: token.expiresAt.toIso8601String(),
    );

    if (token.refreshToken != null && token.refreshToken!.isNotEmpty) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: token.refreshToken,
      );
    } else {
      await _secureStorage.delete(key: _refreshTokenKey);
    }
  }

  @override
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
  }
}

/// クラウドバックアップ連携のサービス。
class CloudBackupService {
  /// OneDrive とバックアップ連携するサービスを生成する。
  CloudBackupService({
    OneDriveAuthClient? authClient,
    OneDriveTokenStore? tokenStore,
    http.Client? httpClient,
    String? oneDriveClientId,
    String? oneDriveTenant,
  }) : _authClient = authClient ?? createDefaultOneDriveAuthClient(),
       _tokenStore = tokenStore ?? SecureOneDriveTokenStore(),
       _httpClient = httpClient ?? http.Client(),
       _configuredOneDriveClientId = oneDriveClientId,
       _configuredOneDriveTenant = oneDriveTenant;

  static const String _defaultTenant = 'consumers';
  static const String _graphApiBase = 'https://graph.microsoft.com/v1.0';
  static const List<String> _oneDriveScopes = <String>[
    'Files.ReadWrite.AppFolder',
  ];

  final OneDriveAuthClient _authClient;
  final OneDriveTokenStore _tokenStore;
  final http.Client _httpClient;
  final String? _configuredOneDriveClientId;
  final String? _configuredOneDriveTenant;

  OneDriveTokenBundle? _cachedToken;
  Uri? _oneDriveAppFolderWebUrl;

  /// 指定クラウド連携が現在プラットフォームで利用可能かを返す。
  bool isProviderSupported(
    CloudStorageProvider provider, {
    TargetPlatform? platform,
    bool? isWeb,
  }) {
    final currentPlatform = platform ?? defaultTargetPlatform;
    final runningOnWeb = isWeb ?? kIsWeb;

    switch (provider) {
      case CloudStorageProvider.oneDrive:
        return !runningOnWeb &&
            (currentPlatform == TargetPlatform.android ||
                currentPlatform == TargetPlatform.iOS ||
                currentPlatform == TargetPlatform.macOS);
    }
  }

  /// OneDrive の認証状態を事前に確立する。
  Future<void> ensureOneDriveAuthentication() async {
    await _getAccessToken(interactive: true);
  }

  /// 保存済みの OneDrive 認証情報を破棄する。
  Future<void> clearOneDriveAuthentication() async {
    _cachedToken = null;
    try {
      await _authClient.signOut();
    } on Exception {
      // ネイティブキャッシュの破棄に失敗しても、ローカル保存の削除は継続する。
    }
    await _tokenStore.clearToken();
  }

  /// 指定クラウドにバックアップをアップロードする。
  Future<void> uploadBackup({
    required CloudStorageProvider provider,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    switch (provider) {
      case CloudStorageProvider.oneDrive:
        await _uploadToOneDrive(
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
        );
    }
  }

  /// 指定クラウドのバックアップ一覧を取得する。
  Future<List<CloudBackupFile>> listBackups({
    required CloudStorageProvider provider,
  }) async {
    switch (provider) {
      case CloudStorageProvider.oneDrive:
        return _listOneDriveBackups();
    }
  }

  /// 指定クラウドからバックアップをダウンロードする。
  Future<Uint8List> downloadBackup({
    required CloudStorageProvider provider,
    required String fileId,
  }) async {
    switch (provider) {
      case CloudStorageProvider.oneDrive:
        return _downloadFromOneDrive(fileId);
    }
  }

  /// 指定クラウドからバックアップを一時ファイルへストリーム保存する。
  ///
  /// 大きなファイルをメモリへ全量展開せずに扱うための API。
  Future<String> downloadBackupToTemporaryFile({
    required CloudStorageProvider provider,
    required String fileId,
    required String suggestedFileName,
  }) async {
    switch (provider) {
      case CloudStorageProvider.oneDrive:
        return _downloadFromOneDriveToTemporaryFile(
          fileId: fileId,
          suggestedFileName: suggestedFileName,
        );
    }
  }

  Future<void> _uploadToOneDrive({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await _ensureOneDriveAppRoot();

    var response = await _authorizedRequest(
      method: 'PUT',
      uri: Uri.parse(
        '$_graphApiBase/me/drive/special/approot:/${Uri.encodeComponent(fileName)}:/content',
      ),
      headers: <String, String>{'Content-Type': mimeType},
      bodyBytes: bytes,
    );

    if (response.statusCode == 404) {
      await _ensureOneDriveAppRoot(forceRefresh: true);
      response = await _authorizedRequest(
        method: 'PUT',
        uri: Uri.parse(
          '$_graphApiBase/me/drive/special/approot:/${Uri.encodeComponent(fileName)}:/content',
        ),
        headers: <String, String>{'Content-Type': mimeType},
        bodyBytes: bytes,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OneDrive への保存に失敗しました: ${response.statusCode}');
    }
  }

  Future<List<CloudBackupFile>> _listOneDriveBackups() async {
    await _ensureOneDriveAppRoot();

    var response = await _authorizedRequest(
      method: 'GET',
      uri: Uri.parse(
        '$_graphApiBase/me/drive/special/approot/children?%24select=id,name,size,lastModifiedDateTime,file',
      ),
    );

    if (response.statusCode == 404) {
      await _ensureOneDriveAppRoot(forceRefresh: true);
      response = await _authorizedRequest(
        method: 'GET',
        uri: Uri.parse(
          '$_graphApiBase/me/drive/special/approot/children?%24select=id,name,size,lastModifiedDateTime,file',
        ),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OneDrive のファイル一覧取得に失敗しました: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final values = decoded['value'];
    if (values is! List) {
      return const <CloudBackupFile>[];
    }

    return values
        .whereType<Map<String, dynamic>>()
        .where((item) {
          final name = (item['name'] as String? ?? '').toLowerCase();
          return name.endsWith('.qrdb') || name.endsWith('.qrjson');
        })
        .map(
          (item) => CloudBackupFile(
            id: item['id'] as String? ?? '',
            name: item['name'] as String? ?? 'unknown',
            modifiedAt:
                DateTime.tryParse(
                  item['lastModifiedDateTime'] as String? ?? '',
                ) ??
                DateTime.fromMillisecondsSinceEpoch(0),
            size: (item['size'] as num?)?.toInt() ?? 0,
            mimeType:
                (item['file'] as Map<String, dynamic>?)?['mimeType']
                    as String? ??
                'application/octet-stream',
          ),
        )
        .where((file) => file.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _ensureOneDriveAppRoot({bool forceRefresh = false}) async {
    if (!forceRefresh && _oneDriveAppFolderWebUrl != null) {
      return;
    }

    final response = await _authorizedRequest(
      method: 'GET',
      uri: Uri.parse(
        '$_graphApiBase/me/drive/special/approot?%24select=id,webUrl',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OneDrive アプリフォルダの初期化に失敗しました: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final webUrl = decoded['webUrl'] as String?;
    _oneDriveAppFolderWebUrl = webUrl == null || webUrl.isEmpty
        ? null
        : Uri.tryParse(webUrl);
  }

  Future<Uint8List> _downloadFromOneDrive(String fileId) async {
    final response = await _authorizedRequest(
      method: 'GET',
      uri: Uri.parse('$_graphApiBase/me/drive/items/$fileId/content'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OneDrive からファイルを取得できませんでした: ${response.statusCode}');
    }

    return response.bodyBytes;
  }

  Future<String> _downloadFromOneDriveToTemporaryFile({
    required String fileId,
    required String suggestedFileName,
  }) async {
    final streamed = await _authorizedStreamedRequest(
      method: 'GET',
      uri: Uri.parse('$_graphApiBase/me/drive/items/$fileId/content'),
    );

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError('OneDrive からファイルを取得できませんでした: ${streamed.statusCode}');
    }

    final temporaryDir = await _resolveTemporaryDirectory();
    final safeName = _sanitizeFileName(suggestedFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${temporaryDir.path}/cloud_restore_${timestamp}_$safeName';
    final file = File(path);

    final sink = file.openWrite();
    try {
      await streamed.stream.pipe(sink);
    } catch (_) {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }

    return file.path;
  }

  Future<http.Response> _authorizedRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Uint8List? bodyBytes,
    String? body,
  }) async {
    final initialAccessToken = await _getAccessToken(interactive: false);
    var response = await _sendRequest(
      method: method,
      uri: uri,
      accessToken: initialAccessToken,
      headers: headers,
      bodyBytes: bodyBytes,
      body: body,
    );

    if (response.statusCode != 401) {
      return response;
    }

    final refreshedAccessToken = await _getAccessToken(
      interactive: false,
      forceRefresh: true,
    );
    response = await _sendRequest(
      method: method,
      uri: uri,
      accessToken: refreshedAccessToken,
      headers: headers,
      bodyBytes: bodyBytes,
      body: body,
    );
    return response;
  }

  Future<http.StreamedResponse> _authorizedStreamedRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
  }) async {
    final initialAccessToken = await _getAccessToken(interactive: false);
    var response = await _sendStreamedRequest(
      method: method,
      uri: uri,
      accessToken: initialAccessToken,
      headers: headers,
    );

    if (response.statusCode != 401) {
      return response;
    }

    await response.stream.drain<void>();
    final refreshedAccessToken = await _getAccessToken(
      interactive: false,
      forceRefresh: true,
    );
    response = await _sendStreamedRequest(
      method: method,
      uri: uri,
      accessToken: refreshedAccessToken,
      headers: headers,
    );
    return response;
  }

  Future<http.Response> _sendRequest({
    required String method,
    required Uri uri,
    required String accessToken,
    Map<String, String>? headers,
    Uint8List? bodyBytes,
    String? body,
  }) {
    final requestHeaders = <String, String>{
      'Authorization': 'Bearer $accessToken',
      ...?headers,
    };

    switch (method) {
      case 'GET':
        return _httpClient.get(uri, headers: requestHeaders);
      case 'PUT':
        if (bodyBytes != null) {
          return _httpClient.put(uri, headers: requestHeaders, body: bodyBytes);
        }
        return _httpClient.put(uri, headers: requestHeaders, body: body);
      case 'POST':
        return _httpClient.post(uri, headers: requestHeaders, body: body);
      default:
        throw UnsupportedError('未対応のHTTPメソッドです: $method');
    }
  }

  Future<http.StreamedResponse> _sendStreamedRequest({
    required String method,
    required Uri uri,
    required String accessToken,
    Map<String, String>? headers,
  }) {
    final request = http.Request(method, uri);
    request.headers.addAll(<String, String>{
      'Authorization': 'Bearer $accessToken',
      ...?headers,
    });
    return _httpClient.send(request);
  }

  String _sanitizeFileName(String fileName) {
    final normalized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (normalized.isEmpty) {
      return 'backup.qrdb';
    }
    return normalized;
  }

  Future<Directory> _resolveTemporaryDirectory() async {
    try {
      return await getTemporaryDirectory();
    } on MissingPluginException {
      return Directory.systemTemp;
    }
  }

  Future<String> _getAccessToken({
    required bool interactive,
    bool forceRefresh = false,
  }) async {
    await _ensureTokenLoaded();

    final current = _cachedToken;
    if (!forceRefresh && current != null && !current.isExpired) {
      return current.accessToken;
    }

    final restored = await _authClient.acquireTokenSilently(
      clientId: _oneDriveClientId,
      authority: _oneDriveAuthority,
      scopes: _oneDriveScopes,
    );
    if (restored != null) {
      _cachedToken = restored;
      await _tokenStore.writeToken(restored);
      return restored.accessToken;
    }

    if (!interactive) {
      throw StateError(
        'OneDrive の認証が必要です。先に「OneDrive へ保存」または「OneDrive から復元」を実行してください。',
      );
    }

    final issued = await _authClient.acquireTokenInteractively(
      clientId: _oneDriveClientId,
      authority: _oneDriveAuthority,
      scopes: _oneDriveScopes,
    );
    _cachedToken = issued;
    await _tokenStore.writeToken(issued);
    return issued.accessToken;
  }

  Future<void> _ensureTokenLoaded() async {
    if (_cachedToken != null) {
      return;
    }
    _cachedToken = await _tokenStore.readToken();
  }

  String get _oneDriveClientId {
    final configured = _configuredOneDriveClientId;
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    const fromDefine = String.fromEnvironment('ONEDRIVE_CLIENT_ID');
    if (fromDefine.isEmpty) {
      throw StateError(
        'OneDrive 機能を使うには --dart-define=ONEDRIVE_CLIENT_ID=<Azure App Client ID> を設定してください。',
      );
    }
    return fromDefine;
  }

  String get _oneDriveTenant {
    final configured = _configuredOneDriveTenant;
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    const tenant = String.fromEnvironment('ONEDRIVE_TENANT_ID');
    return tenant.isEmpty ? _defaultTenant : tenant;
  }

  String get _oneDriveAuthority {
    return 'https://login.microsoftonline.com/$_oneDriveTenant';
  }
}
