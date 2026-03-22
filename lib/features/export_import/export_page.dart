import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/qr_entry_model.dart';
import '../../data/repositories/export_repository.dart';
import '../../data/services/cloud_backup_service.dart';
import '../../providers/providers.dart';
import '../../widgets/tag_chips.dart';

/// エントリのエクスポートページ。
///
/// 全エントリまたは選択したエントリを ZIP または JSON 形式で
/// エクスポートし、share_plus で共有する。
@RoutePage()
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _exporting = false;
  String? _exportingFormat;
  String? _currentTaskLabel;
  ImportExportProgress? _progress;
  ImportExportCancellationToken? _cancellationToken;

  final Set<String> _selectedIds = {};
  bool _selectAll = true;
  final Set<String> _tagFilterIds = {};
  String? _categoryFilterId;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync = ref.watch(qrEntriesProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final cloudService = ref.read(cloudBackupServiceProvider);
    final supportsOneDrive = cloudService.isProviderSupported(
      CloudStorageProvider.oneDrive,
    );

    return PopScope(
      canPop: !_exporting,
      child: Scaffold(
        appBar: AppBar(title: const Text('エクスポート')),
        body: entriesAsync.when(
          data: (entries) => tagsAsync.when(
            data: (tags) => categoriesAsync.when(
              data: (categories) {
                if (entries.isEmpty) {
                  return const Center(child: Text('エクスポートするデータがありません'));
                }

                final filteredEntries = _applyFilters(
                  entries: entries,
                  tagFilters: _tagFilterIds,
                  categoryId: _categoryFilterId,
                  query: _query,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      ignoring: _exporting,
                      child: Column(
                        children: [
                          _buildFilterArea(tags, categories),
                          CheckboxListTile(
                            title: const Text('フィルタ結果をすべて選択'),
                            value: _selectAll,
                            onChanged: (value) {
                              setState(() {
                                _selectAll = value ?? true;
                                if (_selectAll) {
                                  _selectedIds.clear();
                                }
                              });
                            },
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: filteredEntries.isEmpty
                                ? const Center(child: Text('条件に一致する対象がありません'))
                                : ListView.builder(
                                    itemCount: filteredEntries.length,
                                    itemBuilder: (context, index) {
                                      final entry = filteredEntries[index];
                                      final isSelected =
                                          _selectAll ||
                                          _selectedIds.contains(entry.id);
                                      return CheckboxListTile(
                                        title: Text(entry.name),
                                        subtitle: Text(
                                          '${_formatSize(entry.dataSize)} · ${entry.chunkCount}枚',
                                        ),
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectAll = false;
                                              _selectedIds.add(entry.id);
                                              return;
                                            }

                                            if (_selectAll) {
                                              _selectedIds
                                                ..clear()
                                                ..addAll(
                                                  filteredEntries
                                                      .map((item) => item.id)
                                                      .where(
                                                        (id) => id != entry.id,
                                                      ),
                                                );
                                              _selectAll = false;
                                            } else {
                                              _selectedIds.remove(entry.id);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          _buildBottomActions(
                            context: context,
                            colorScheme: colorScheme,
                            filteredEntries: filteredEntries,
                            supportsOneDrive: supportsOneDrive,
                          ),
                        ],
                      ),
                    ),
                    if (_exporting) ...[
                      const ModalBarrier(
                        dismissible: false,
                        color: Colors.black38,
                      ),
                      Center(child: _buildProgressCard()),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
        ),
      ),
    );
  }

  Widget _buildFilterArea(List<TagModel> tags, List<CategoryModel> categories) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: '名称・説明で絞り込み',
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _categoryFilterId,
              decoration: const InputDecoration(labelText: 'カテゴリフィルター'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('すべて'),
                ),
                const DropdownMenuItem<String?>(
                  value: '',
                  child: Text('カテゴリ未設定'),
                ),
                ...categories.map(
                  (category) => DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _categoryFilterId = value),
            ),
            const SizedBox(height: 12),
            Text('タグフィルター', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TagChips(
              tags: tags,
              selectedTagIds: _tagFilterIds.toList(growable: false),
              selectable: true,
              maxHeight: 120,
              onTagToggled: (tagId) {
                setState(() {
                  if (_tagFilterIds.contains(tagId)) {
                    _tagFilterIds.remove(tagId);
                  } else {
                    _tagFilterIds.add(tagId);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions({
    required BuildContext context,
    required ColorScheme colorScheme,
    required List<QrEntryModel> filteredEntries,
    required bool supportsOneDrive,
  }) {
    final hasCloudButtons = supportsOneDrive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _export('json', filteredEntries),
                    icon: _exporting && _exportingFormat == 'json'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.data_object),
                    label: const Text('JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _export('zip', filteredEntries),
                    icon: _exporting && _exportingFormat == 'zip'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive),
                    label: const Text('ZIP'),
                  ),
                ),
              ],
            ),
            if (hasCloudButtons) ...[
              const SizedBox(height: 8),
              Text(
                '対応プラットフォームではクラウドへ直接保存できます',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (supportsOneDrive)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exporting
                            ? null
                            : () => _backupToCloud(
                                provider: CloudStorageProvider.oneDrive,
                                filteredEntries: filteredEntries,
                              ),
                        icon: const Icon(Icons.cloud_done_outlined),
                        label: const Text('OneDriveへ保存'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _progress;
    final fraction = progress?.fraction;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('エクスポート処理中', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_currentTaskLabel != null)
                Text(
                  _currentTaskLabel!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_currentTaskLabel != null) const SizedBox(height: 8),
              Text(progress?.message ?? '処理中...'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: fraction),
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

  Future<void> _export(
    String format,
    List<QrEntryModel> filteredEntries,
  ) async {
    if (filteredEntries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポート対象がありません')));
      return;
    }

    final selectedIds = _selectAll
        ? filteredEntries.map((entry) => entry.id).toList(growable: false)
        : filteredEntries
              .where((entry) => _selectedIds.contains(entry.id))
              .map((entry) => entry.id)
              .toList(growable: false);

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポート対象を選択してください')));
      return;
    }

    final cancellationToken = ImportExportCancellationToken();
    setState(() {
      _exporting = true;
      _exportingFormat = format;
      _currentTaskLabel = 'ローカルにエクスポート';
      _progress = const ImportExportProgress(
        phase: ImportExportProcessPhase.preparing,
        processed: 0,
        total: 0,
        message: 'エクスポート準備中',
      );
      _cancellationToken = cancellationToken;
    });

    try {
      final exportRepo = ref.read(exportRepositoryProvider);
      final dbId = ref.read(currentDatabaseIdProvider);

      String filePath;
      if (format == 'zip') {
        filePath = await exportRepo.exportAsZip(
          entryIds: selectedIds,
          databaseId: dbId,
          cancellationToken: cancellationToken,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        );
      } else {
        filePath = await exportRepo.exportAsJson(
          entryIds: selectedIds,
          databaseId: dbId,
          cancellationToken: cancellationToken,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        );
      }

      if (!mounted) return;

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: '保存先を選択してください',
          fileName: filePath.split(Platform.pathSeparator).last,
          type: FileType.custom,
          allowedExtensions: [format == 'zip' ? 'qrdb' : 'qrjson'],
        );
        if (savePath == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('エクスポートをキャンセルしました')));
          return;
        }
        final bytes = await File(filePath).readAsBytes();
        await File(savePath).writeAsBytes(bytes, flush: true);
      } else {
        // モバイル等では既存どおり共有シートを利用する。
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], text: 'QR Code Manager エクスポート'),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポートが完了しました')));
    } on ImportExportCanceledException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポートをキャンセルしました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportingFormat = null;
          _currentTaskLabel = null;
          _progress = null;
          _cancellationToken = null;
        });
      }
    }
  }

  Future<void> _backupToCloud({
    required CloudStorageProvider provider,
    required List<QrEntryModel> filteredEntries,
  }) async {
    if (filteredEntries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポート対象がありません')));
      return;
    }

    final selectedIds = _selectAll
        ? filteredEntries.map((entry) => entry.id).toList(growable: false)
        : filteredEntries
              .where((entry) => _selectedIds.contains(entry.id))
              .map((entry) => entry.id)
              .toList(growable: false);
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポート対象を選択してください')));
      return;
    }

    final cloudService = ref.read(cloudBackupServiceProvider);
    if (provider == CloudStorageProvider.oneDrive) {
      await cloudService.ensureOneDriveAuthentication();
    }

    final cancellationToken = ImportExportCancellationToken();
    setState(() {
      _exporting = true;
      _exportingFormat = 'zip';
      _currentTaskLabel = 'OneDrive へバックアップ';
      _progress = const ImportExportProgress(
        phase: ImportExportProcessPhase.preparing,
        processed: 0,
        total: 0,
        message: 'エクスポート準備中',
      );
      _cancellationToken = cancellationToken;
    });

    try {
      final exportRepo = ref.read(exportRepositoryProvider);
      final dbId = ref.read(currentDatabaseIdProvider);
      final filePath = await exportRepo.exportAsZip(
        entryIds: selectedIds,
        databaseId: dbId,
        cancellationToken: cancellationToken,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );
      final bytes = await File(filePath).readAsBytes();
      final fileName = filePath.split(Platform.pathSeparator).last;
      await cloudService.uploadBackup(
        provider: provider,
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OneDrive への保存が完了しました')));
    } on ImportExportCanceledException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('バックアップをキャンセルしました')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('クラウド保存に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportingFormat = null;
          _currentTaskLabel = null;
          _progress = null;
          _cancellationToken = null;
        });
      }
    }
  }

  List<QrEntryModel> _applyFilters({
    required List<QrEntryModel> entries,
    required Set<String> tagFilters,
    required String? categoryId,
    required String query,
  }) {
    final normalizedQuery = query.toLowerCase();
    return entries
        .where((entry) {
          if (normalizedQuery.isNotEmpty) {
            final matchedText =
                entry.name.toLowerCase().contains(normalizedQuery) ||
                entry.description.toLowerCase().contains(normalizedQuery);
            if (!matchedText) return false;
          }

          if (categoryId != null) {
            if (categoryId.isEmpty) {
              if (entry.categoryId != null) return false;
            } else if (entry.categoryId != categoryId) {
              return false;
            }
          }

          if (tagFilters.isNotEmpty) {
            final entryTagIds = entry.tags.map((tag) => tag.id).toSet();
            if (!tagFilters.every(entryTagIds.contains)) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
