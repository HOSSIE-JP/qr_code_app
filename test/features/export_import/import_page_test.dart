import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';
import 'package:qr_code_app/data/repositories/export_repository.dart';
import 'package:qr_code_app/data/repositories/qr_repository.dart';
import 'package:qr_code_app/data/repositories/tag_repository.dart';
import 'package:qr_code_app/data/services/cloud_backup_service.dart';
import 'package:qr_code_app/data/services/import_file_picker_service.dart';
import 'package:qr_code_app/features/export_import/import_page.dart';
import 'package:qr_code_app/providers/providers.dart';

class _FakeImportFilePickerService extends ImportFilePickerService {
  _FakeImportFilePickerService(this._result);

  final FilePickerResult? _result;

  @override
  Future<FilePickerResult?> pickImportFile() async {
    return _result;
  }
}

class _FakeImportExportRepository extends ExportRepository {
  _FakeImportExportRepository(this.db)
    : super(QrRepository(db), TagRepository(db));

  final AppDatabase db;
  int jsonImportCount = 0;
  int zipImportFromPathCount = 0;
  bool enableSlowMode = false;

  @override
  Future<int> importFromJson(
    String jsonString, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    jsonImportCount++;
    if (enableSlowMode) {
      for (var index = 1; index <= 8; index++) {
        cancellationToken?.throwIfCancellationRequested();
        onProgress?.call(
          ImportExportProgress(
            phase: ImportExportProcessPhase.processingEntries,
            processed: index,
            total: 8,
            message: 'テスト処理中 $index/8',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
    return 2;
  }

  @override
  Future<int> importFromZip(
    Uint8List zipBytes, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    return 1;
  }

  @override
  Future<int> importFromZipFile(
    String zipFilePath, {
    String? databaseId,
    ImportExportProgressCallback? onProgress,
    ImportExportCancellationToken? cancellationToken,
  }) async {
    zipImportFromPathCount += 1;
    return 1;
  }
}

class _FakeCloudBackupService extends CloudBackupService {
  _FakeCloudBackupService({
    required this.files,
    required this.downloadBytes,
    this.supportOneDrive = true,
  });

  final List<CloudBackupFile> files;
  final Uint8List downloadBytes;
  final bool supportOneDrive;
  int downloadBackupCallCount = 0;
  int downloadBackupToTemporaryFileCallCount = 0;

  @override
  bool isProviderSupported(
    CloudStorageProvider provider, {
    TargetPlatform? platform,
    bool? isWeb,
  }) {
    switch (provider) {
      case CloudStorageProvider.oneDrive:
        return supportOneDrive;
    }
  }

  @override
  Future<void> ensureOneDriveAuthentication() async {}

  @override
  Future<List<CloudBackupFile>> listBackups({
    required CloudStorageProvider provider,
  }) async {
    return files;
  }

  @override
  Future<Uint8List> downloadBackup({
    required CloudStorageProvider provider,
    required String fileId,
  }) async {
    downloadBackupCallCount += 1;
    return downloadBytes;
  }

  @override
  Future<String> downloadBackupToTemporaryFile({
    required CloudStorageProvider provider,
    required String fileId,
    required String suggestedFileName,
  }) async {
    downloadBackupToTemporaryFileCallCount += 1;
    final path = '${Directory.systemTemp.path}/fake_cloud_$suggestedFileName';
    final file = File(path);
    await file.writeAsBytes(downloadBytes, flush: true);
    return path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late _FakeImportExportRepository fakeRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeRepository = _FakeImportExportRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTarget({required ImportFilePickerService pickerService}) {
    return ProviderScope(
      overrides: [
        exportRepositoryProvider.overrideWith((ref) => fakeRepository),
        importFilePickerServiceProvider.overrideWith((ref) => pickerService),
      ],
      child: const MaterialApp(home: ImportPage()),
    );
  }

  testWidgets('JSONファイルからインポート成功時に件数メッセージを表示する', (tester) async {
    final payload = jsonEncode(<String, dynamic>{
      'version': 2,
      'tags': <Object>[],
      'categories': <Object>[],
      'entries': <Object>[],
    });

    final file = PlatformFile(
      name: 'backup.qrjson',
      size: payload.length,
      bytes: Uint8List.fromList(utf8.encode(payload)),
    );
    final picker = _FakeImportFilePickerService(FilePickerResult([file]));

    await tester.pumpWidget(buildTarget(pickerService: picker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JSONファイルからインポート'));
    await tester.pumpAndSettle();

    expect(find.text('2 件のエントリをインポートしました'), findsOneWidget);
    expect(fakeRepository.jsonImportCount, 1);
  });

  testWidgets('インポート中にキャンセルボタンで処理を中断できる', (tester) async {
    fakeRepository.enableSlowMode = true;
    final payload = jsonEncode(<String, dynamic>{
      'version': 2,
      'tags': <Object>[],
      'categories': <Object>[],
      'entries': <Object>[],
    });

    final file = PlatformFile(
      name: 'backup.qrjson',
      size: payload.length,
      bytes: Uint8List.fromList(utf8.encode(payload)),
    );
    final picker = _FakeImportFilePickerService(FilePickerResult([file]));

    await tester.pumpWidget(buildTarget(pickerService: picker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JSONファイルからインポート'));
    await tester.pump();

    expect(find.text('インポート処理中'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('インポート処理中'), findsNothing);
    expect(find.text('インポートをキャンセルしました'), findsOneWidget);
  });

  testWidgets('OneDriveバックアップ選択から復元できる', (tester) async {
    final payload = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, dynamic>{
          'version': 2,
          'tags': <Object>[],
          'categories': <Object>[],
          'entries': <Object>[],
        }),
      ),
    );

    final fakeCloudService = _FakeCloudBackupService(
      files: [
        CloudBackupFile(
          id: 'onedrive-file-1',
          name: 'cloud_backup.qrjson',
          modifiedAt: DateTime(2026, 3, 21),
          size: payload.length,
          mimeType: 'application/json',
        ),
      ],
      downloadBytes: payload,
      supportOneDrive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportRepositoryProvider.overrideWith((ref) => fakeRepository),
          importFilePickerServiceProvider.overrideWith(
            (ref) => _FakeImportFilePickerService(null),
          ),
          cloudBackupServiceProvider.overrideWith((ref) => fakeCloudService),
        ],
        child: const MaterialApp(home: ImportPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OneDrive から復元'));
    await tester.pumpAndSettle();

    expect(find.text('cloud_backup.qrjson'), findsOneWidget);
    await tester.tap(find.text('cloud_backup.qrjson'));
    await tester.pumpAndSettle();

    expect(find.text('2 件のエントリをインポートしました'), findsOneWidget);
    expect(fakeRepository.jsonImportCount, 1);
  });

  testWidgets('OneDriveのZIP復元はファイルパス経由で取り込む', (tester) async {
    final payload = Uint8List.fromList(const [1, 2, 3, 4]);

    final fakeCloudService = _FakeCloudBackupService(
      files: [
        CloudBackupFile(
          id: 'onedrive-file-zip',
          name: 'cloud_backup.qrdb',
          modifiedAt: DateTime(2026, 3, 21),
          size: payload.length,
          mimeType: 'application/zip',
        ),
      ],
      downloadBytes: payload,
      supportOneDrive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportRepositoryProvider.overrideWith((ref) => fakeRepository),
          importFilePickerServiceProvider.overrideWith(
            (ref) => _FakeImportFilePickerService(null),
          ),
          cloudBackupServiceProvider.overrideWith((ref) => fakeCloudService),
        ],
        child: const MaterialApp(home: ImportPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OneDrive から復元'));
    await tester.pumpAndSettle();

    expect(find.text('cloud_backup.qrdb'), findsOneWidget);
    await tester.tap(find.text('cloud_backup.qrdb'));
    for (var index = 0; index < 30; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (fakeCloudService.downloadBackupToTemporaryFileCallCount > 0) {
        break;
      }
    }

    expect(fakeCloudService.downloadBackupToTemporaryFileCallCount, 1);
    expect(fakeCloudService.downloadBackupCallCount, 0);
  });

  testWidgets('OneDrive非対応時は復元ボタンを表示しない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportRepositoryProvider.overrideWith((ref) => fakeRepository),
          importFilePickerServiceProvider.overrideWith(
            (ref) => _FakeImportFilePickerService(null),
          ),
          cloudBackupServiceProvider.overrideWith(
            (ref) => _FakeCloudBackupService(
              files: const [],
              downloadBytes: Uint8List(0),
              supportOneDrive: false,
            ),
          ),
        ],
        child: const MaterialApp(home: ImportPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OneDrive から復元'), findsNothing);
  });

  testWidgets('OneDrive復元ボタンを表示する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportRepositoryProvider.overrideWith((ref) => fakeRepository),
          importFilePickerServiceProvider.overrideWith(
            (ref) => _FakeImportFilePickerService(null),
          ),
          cloudBackupServiceProvider.overrideWith(
            (ref) => _FakeCloudBackupService(
              files: const [],
              downloadBytes: Uint8List(0),
              supportOneDrive: true,
            ),
          ),
        ],
        child: const MaterialApp(home: ImportPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OneDrive から復元'), findsOneWidget);
  });
}
