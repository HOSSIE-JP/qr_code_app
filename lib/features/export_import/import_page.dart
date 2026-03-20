import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('インポート')),
      body: Padding(
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
            const SizedBox(height: 32),

            // ZIP import
            FilledButton.icon(
              onPressed: _importing ? null : () => _importFile('zip'),
              icon: const Icon(Icons.archive),
              label: const Text('ZIPファイルからインポート'),
            ),
            const SizedBox(height: 12),

            // JSON import
            OutlinedButton.icon(
              onPressed: _importing ? null : () => _importFile('json'),
              icon: const Icon(Icons.data_object),
              label: const Text('JSONファイルからインポート'),
            ),

            if (_importing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
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
    );
  }

  Future<void> _importFile(String format) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: kIsWeb,
    );
    if (result == null) return;

    final file = result.files.single;
    if (!kIsWeb && file.size > _maxImportFileSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ファイルサイズが大きすぎるため読み込めません（80MBまで）'),
        ),
      );
      return;
    }

    setState(() {
      _importing = true;
      _statusMessage = null;
    });

    try {
      final exportRepo = ref.read(exportRepositoryProvider);
      final dbId = ref.read(currentDatabaseIdProvider);
      int importedCount;

      if (format == 'zip') {
        final bytes = await _readFileBytes(file);
        importedCount = await exportRepo.importFromZip(bytes, databaseId: dbId);
      } else {
        final jsonString = await _readFileAsString(file);
        importedCount = await exportRepo.importFromJson(
          jsonString,
          databaseId: dbId,
        );
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = '$importedCount 件のエントリをインポートしました';
      });
      ref.invalidate(qrEntriesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('インポートに失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
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
