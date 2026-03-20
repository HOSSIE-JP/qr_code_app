import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/providers.dart';

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
  final Set<String> _selectedIds = {};
  bool _selectAll = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync = ref.watch(qrEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('エクスポート')),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('エクスポートするデータがありません'));
          }
          return Column(
            children: [
              // Select all toggle
              CheckboxListTile(
                title: const Text('すべて選択'),
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

              // Entry list
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isSelected =
                        _selectAll || _selectedIds.contains(entry.id);
                    return CheckboxListTile(
                      title: Text(entry.name),
                      subtitle: Text(
                        '${_formatSize(entry.dataSize)} · ${entry.chunkCount}枚',
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectAll = false;
                          if (value == true) {
                            _selectedIds.add(entry.id);
                          } else {
                            _selectedIds.remove(entry.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              // Export buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exporting ? null : () => _export('json'),
                          icon: const Icon(Icons.data_object),
                          label: const Text('JSON'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _exporting ? null : () => _export('zip'),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.archive),
                          label: const Text('ZIP'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final exportRepo = ref.read(exportRepositoryProvider);
      final entryIds = _selectAll ? null : _selectedIds.toList();
      final dbId = ref.read(currentDatabaseIdProvider);

      String filePath;
      if (format == 'zip') {
        filePath = await exportRepo.exportAsZip(
          entryIds: entryIds,
          databaseId: dbId,
        );
      } else {
        filePath = await exportRepo.exportAsJson(
          entryIds: entryIds,
          databaseId: dbId,
        );
      }

      if (!mounted) return;

      // Share the file
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'QR Code Manager エクスポート'),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エクスポートが完了しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
