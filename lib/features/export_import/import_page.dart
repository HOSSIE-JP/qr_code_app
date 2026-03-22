import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/export_repository.dart';
import '../../data/services/cloud_backup_service.dart';
import '../../providers/providers.dart';

/// エントリのインポートページ。
///
/// エクスポートした ZIP または JSON ファイルを選択してインポートする。
/// 既存 ID と重複するエントリはスキップされる。
@RoutePage()
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  static const int _maxImportFileSizeBytes = 80 * 1024 * 1024;

  bool _importing = false;
  String? _statusMessage;
  ImportExportProgress? _progress;
  ImportExportCancellationToken? _cancellationToken;
  String? _currentTaskLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cloudService = ref.read(cloudBackupServiceProvider);
    final supportsOneDrive = cloudService.isProviderSupported(
      CloudStorageProvider.oneDrive,
    );
    final hasCloudActions = supportsOneDrive;

    return PopScope(
      canPop: !_importing,
      child: Scaffold(
        appBar: AppBar(title: const Text('インポート')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              ignoring: _importing,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.download,
                      size: 64,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'データをインポート',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'エクスポートしたZIPまたはJSONファイルを選択してください',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      supportsOneDrive
                          ? 'OneDrive から直接復元できます'
                          : 'OneDrive 復元はこのプラットフォームでは利用できません',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _importing ? null : () => _importFile('zip'),
                      icon: const Icon(Icons.archive),
                      label: const Text('ZIPファイルからインポート'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _importing ? null : () => _importFile('json'),
                      icon: const Icon(Icons.data_object),
                      label: const Text('JSONファイルからインポート'),
                    ),
                    if (hasCloudActions) ...[
                      const SizedBox(height: 20),
                      Text(
                        'クラウドから復元',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (supportsOneDrive)
                        OutlinedButton.icon(
                          onPressed: _importing
                              ? null
                              : () => _importFromCloud(
                                  CloudStorageProvider.oneDrive,
                                ),
                          icon: const Icon(Icons.cloud_done_outlined),
                          label: const Text('OneDrive から復元'),
                        ),
                    ],
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 24),
                      Card(
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_statusMessage!)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_importing) ...[
              const ModalBarrier(dismissible: false, color: Colors.black38),
              Center(child: _buildProgressCard()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('インポート処理中', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_currentTaskLabel != null)
                Text(
                  _currentTaskLabel!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_currentTaskLabel != null) const SizedBox(height: 8),
              Text(progress?.message ?? '処理中...'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress?.fraction),
              const SizedBox(height: 8),
              Text(
                progress == null
                    ? '進捗を計算中...'
                    : '${progress.processed} / ${progress.total <= 0 ? '---' : progress.total}',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancellationToken?.requestCancel(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('キャンセル'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFile(String format) async {
    final picker = ref.read(importFilePickerServiceProvider);
    final result = await picker.pickImportFile();
    if (result == null) return;

    final file = result.files.single;
    if (!kIsWeb && file.size > _maxImportFileSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルサイズが大きすぎるため読み込めません（80MBまで）')),
      );
      return;
    }

    _startImport(taskLabel: 'ローカルファイルから復元');

    try {
      final importedCount = await _importFromPlatformFile(file, format: format);

      if (!mounted) return;
      setState(() {
        _statusMessage = '$importedCount 件のエントリをインポートしました';
      });
      ref.invalidate(qrEntriesProvider);
    } on Object catch (error) {
      _handleImportError(error);
    } finally {
      _finishImport();
    }
  }

  Future<void> _importFromCloud(CloudStorageProvider provider) async {
    final cloudService = ref.read(cloudBackupServiceProvider);

    if (provider == CloudStorageProvider.oneDrive) {
      await cloudService.ensureOneDriveAuthentication();
    }

    try {
      final files = await cloudService.listBackups(provider: provider);
      if (!mounted) return;
      if (files.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('復元可能なバックアップがありません')));
        return;
      }

      final selected = await _selectCloudFile(provider, files);
      if (selected == null) return;

      _startImport(taskLabel: 'OneDrive から復元');
      final format = _inferFormatFromName(selected.name);
      int importedCount;
      if (!kIsWeb && format == 'zip') {
        final temporaryPath = await cloudService.downloadBackupToTemporaryFile(
          provider: provider,
          fileId: selected.id,
          suggestedFileName: selected.name,
        );
        try {
          final exportRepo = ref.read(exportRepositoryProvider);
          final dbId = ref.read(currentDatabaseIdProvider);
          final token = _cancellationToken!;
          importedCount = await exportRepo.importFromZipFile(
            temporaryPath,
            databaseId: dbId,
            cancellationToken: token,
            onProgress: _onProgress,
          );
        } finally {
          final temporaryFile = File(temporaryPath);
          if (await temporaryFile.exists()) {
            await temporaryFile.delete();
          }
        }
      } else {
        final bytes = await cloudService.downloadBackup(
          provider: provider,
          fileId: selected.id,
        );
        importedCount = await _importFromBytes(bytes, format: format);
      }
      if (!mounted) return;
      setState(() {
        _statusMessage = '$importedCount 件のエントリをインポートしました';
      });
      ref.invalidate(qrEntriesProvider);
    } on Object catch (error) {
      _handleImportError(error);
    } finally {
      _finishImport();
    }
  }

  Future<int> _importFromPlatformFile(
    PlatformFile file, {
    required String format,
  }) async {
    if (format == 'zip') {
      if (!kIsWeb && file.path != null) {
        final exportRepo = ref.read(exportRepositoryProvider);
        final dbId = ref.read(currentDatabaseIdProvider);
        final token = _cancellationToken!;
        return exportRepo.importFromZipFile(
          file.path!,
          databaseId: dbId,
          cancellationToken: token,
          onProgress: _onProgress,
        );
      }
      final bytes = await _readFileBytes(file);
      return _importFromBytes(bytes, format: format);
    }
    final jsonString = await _readFileAsString(file);
    return _importFromJsonString(jsonString);
  }

  Future<int> _importFromBytes(Uint8List bytes, {required String format}) {
    if (format == 'zip') {
      return _importFromZipBytes(bytes);
    }
    final jsonString = utf8.decode(bytes);
    return _importFromJsonString(jsonString);
  }

  Future<int> _importFromZipBytes(Uint8List bytes) async {
    final exportRepo = ref.read(exportRepositoryProvider);
    final dbId = ref.read(currentDatabaseIdProvider);
    final token = _cancellationToken!;
    return exportRepo.importFromZip(
      bytes,
      databaseId: dbId,
      cancellationToken: token,
      onProgress: _onProgress,
    );
  }

  Future<int> _importFromJsonString(String jsonString) async {
    final exportRepo = ref.read(exportRepositoryProvider);
    final dbId = ref.read(currentDatabaseIdProvider);
    final token = _cancellationToken!;
    return exportRepo.importFromJson(
      jsonString,
      databaseId: dbId,
      cancellationToken: token,
      onProgress: _onProgress,
    );
  }

  void _onProgress(ImportExportProgress progress) {
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  void _startImport({required String taskLabel}) {
    setState(() {
      _importing = true;
      _statusMessage = null;
      _currentTaskLabel = taskLabel;
      _progress = const ImportExportProgress(
        phase: ImportExportProcessPhase.preparing,
        processed: 0,
        total: 0,
        message: 'インポート準備中',
      );
      _cancellationToken = ImportExportCancellationToken();
    });
  }

  void _finishImport() {
    if (!mounted) return;
    setState(() {
      _importing = false;
      _progress = null;
      _cancellationToken = null;
      _currentTaskLabel = null;
    });
  }

  void _handleImportError(Object error) {
    if (!mounted) return;
    if (error is ImportExportCanceledException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('インポートをキャンセルしました')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('インポートに失敗しました: $error')));
  }

  String _inferFormatFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.qrdb') || lower.endsWith('.zip')) {
      return 'zip';
    }
    return 'json';
  }

  Future<CloudBackupFile?> _selectCloudFile(
    CloudStorageProvider provider,
    List<CloudBackupFile> files,
  ) {
    return showModalBottomSheet<CloudBackupFile>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('OneDrive バックアップを選択')),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ListTile(
                      title: Text(file.name),
                      subtitle: Text(
                        '${file.modifiedAt.toLocal()} · ${_formatSize(file.size)}',
                      ),
                      onTap: () => Navigator.of(context).pop(file),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 選択ファイルを UTF-8 文字列として読み込む。
  Future<String> _readFileAsString(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    final path = file.path;
    if (path == null) {
      throw StateError('ファイルパスを取得できませんでした');
    }
    return File(path).openRead().transform(utf8.decoder).join();
  }

  /// 選択ファイルをバイト列として読み込む。
  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    final path = file.path;
    if (path == null) {
      throw StateError('ファイルパスを取得できませんでした');
    }
    return File(path).readAsBytes();
  }
}
