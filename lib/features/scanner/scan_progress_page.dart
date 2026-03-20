import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// スキャン結果の確認・保存ページ。
///
/// [isTextMode] が true の場合、データは UTF-8 テキストとして DB に格納し、
/// QR コードもプレーンテキストモードで生成される。
@RoutePage()
class ScanProgressPage extends ConsumerStatefulWidget {
  const ScanProgressPage({
    super.key,
    required this.scannedData,
    this.isTextMode = false,
  });

  final Uint8List scannedData;
  final bool isTextMode;

  @override
  ConsumerState<ScanProgressPage> createState() => _ScanProgressPageState();
}

class _ScanProgressPageState extends ConsumerState<ScanProgressPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('スキャン結果')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isTextMode
                              ? Icons.text_fields
                              : Icons.qr_code_2,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isTextMode ? 'テキストQRコード' : '標準QRコード',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'データサイズ: ${_formatSize(widget.scannedData.length)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    // Show data preview (text if possible)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dataPreview(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('保存情報', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称 *',
                hintText: 'QRコードの名前を入力',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '説明・メモ',
                hintText: '説明やメモを入力（任意）',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// スキャンデータを DB に保存する。
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称を入力してください')));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(qrRepositoryProvider);
      final dbId = ref.read(currentDatabaseIdProvider);
      await repo.createEntry(
        name: name,
        description: _descController.text.trim(),
        data: widget.scannedData,
        chunkCount: 1,
        isTextMode: widget.isTextMode,
        databaseId: dbId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));
      context.router.popUntilRoot();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// スキャンされたデータのプレビュー文字列を返す。
  ///
  /// テキストモードの場合は UTF-8 文字列としてそのまま表示し、
  /// バイナリモードの場合は可読テキスト判定後、不可ならヘックスダンプを表示する。
  String _dataPreview() {
    // テキストモードの場合は UTF-8 として直接表示
    if (widget.isTextMode) {
      final text = utf8.decode(widget.scannedData, allowMalformed: true);
      return text.length > 500 ? '${text.substring(0, 500)}...' : text;
    }
    try {
      final text = String.fromCharCodes(widget.scannedData);
      // 印字可能な ASCII テキストかどうかを判定
      if (text.runes.every(
        (r) => r >= 0x20 && r < 0x7F || r == 0x0A || r == 0x0D,
      )) {
        return text.length > 500 ? '${text.substring(0, 500)}...' : text;
      }
    } catch (_) {}
    // バイナリデータはヘックスダンプで表示
    final hex = widget.scannedData
        .take(128)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    return '$hex${widget.scannedData.length > 128 ? ' ...' : ''}';
  }
}
