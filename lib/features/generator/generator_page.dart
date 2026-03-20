import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';

/// QR コード生成ページ。テキスト入力タブとファイル入力タブを持つ。
///
/// テキストモードでは入力文字列をそのまま QR コードに格納する（標準互換）。
/// ファイルモードではファイルデータを保存し、QR コード容量内ならば
/// base64 エンコードした標準 QR コードとして表示する。
@RoutePage()
class GeneratorPage extends ConsumerStatefulWidget {
  const GeneratorPage({super.key});

  @override
  ConsumerState<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends ConsumerState<GeneratorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  Uint8List? _fileData;
  String? _fileName;
  bool _isDragging = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード生成'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'テキスト'),
            Tab(icon: Icon(Icons.attach_file), text: 'ファイル'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(theme, colorScheme),
                _buildFileTab(theme, colorScheme),
              ],
            ),
          ),
          _buildBottomBar(theme),
        ],
      ),
    );
  }

  Widget _buildTextTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称 *',
              hintText: 'QRコードの名前',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'テキストデータ',
              hintText: 'QRコードに変換するテキストを入力',
              alignLabelWithHint: true,
            ),
            maxLines: 10,
            minLines: 5,
          ),
          const SizedBox(height: 8),
          if (_textController.text.isNotEmpty)
            Text(
              'データサイズ: ${utf8.encode(_textController.text).length} bytes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称 *',
              hintText: 'QRコードの名前',
            ),
          ),
          const SizedBox(height: 16),
          DropTarget(
            onDragDone: (detail) async {
              if (detail.files.isNotEmpty) {
                final file = detail.files.first;
                final bytes = await file.readAsBytes();
                setState(() {
                  _fileData = bytes;
                  _fileName = file.name;
                  _isDragging = false;
                  if (_nameController.text.isEmpty) {
                    _nameController.text = file.name;
                  }
                });
              }
            },
            onDragEntered: (_) => setState(() => _isDragging = true),
            onDragExited: (_) => setState(() => _isDragging = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: _isDragging
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDragging
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: _isDragging ? 2 : 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickFile,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _fileData != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      size: 48,
                      color: _fileData != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileData != null
                          ? '$_fileName (${_formatSize(_fileData!.length)})'
                          : 'ファイルを選択またはドロップ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_fileData == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '上限: ${_formatSize(AppConstants.qrMaxTextBytes)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_fileData != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fileData!.length > AppConstants.qrMaxTextBytes
                        ? '⚠️ データが QR コード容量を超えています'
                        : '✅ QRコードに変換できます',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _fileData!.length > AppConstants.qrMaxTextBytes
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _fileData = null;
                    _fileName = null;
                  }),
                  child: const Text('クリア'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code),
              label: const Text('QRコード生成・保存'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _generating ? null : _createWithoutQr,
              icon: const Icon(Icons.note_add),
              label: const Text('QRコードなしで保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileData = result.files.single.bytes!;
        _fileName = result.files.single.name;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.files.single.name;
        }
      });
    }
  }

  /// テキストまたはファイルデータから QR コードエントリを生成して DB に保存する。
  ///
  /// テキストモード: プレーンテキストをそのまま格納（標準 QR リーダーで読める）。
  /// ファイルモード: バイナリデータを格納し、QR 容量内であれば base64 QR 表示可能。
  Future<void> _generate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称を入力してください')));
      return;
    }

    // テキストタブ: プレーンテキストモード（標準 QR リーダー互換）
    if (_tabController.index == 0) {
      final text = _textController.text;
      if (text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('テキストを入力してください')));
        return;
      }
      // QR コードの最大バイナリ容量（Version 40, ECC-L）は約 2,953 バイト。
      // UTF-8 エンコード後のサイズで判定する。
      final textBytes = Uint8List.fromList(utf8.encode(text));
      if (textBytes.length > 2953) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'テキストが長すぎます（約2,953バイト以下にしてください）。'
              '大容量データはファイルタブをご利用ください。',
            ),
          ),
        );
        return;
      }

      setState(() => _generating = true);
      try {
        final repo = ref.read(qrRepositoryProvider);
        final dbId = ref.read(currentDatabaseIdProvider);
        // テキストモード: チャンキングなし、isTextMode: true
        final entry = await repo.createEntry(
          name: name,
          data: textBytes,
          chunkCount: 1,
          isTextMode: true,
          databaseId: dbId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QRコードを生成しました')));
        context.router.replace(DetailRoute(entryId: entry.id));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成に失敗しました: $e')));
      } finally {
        if (mounted) setState(() => _generating = false);
      }
      return;
    }

    // ファイルタブ: バイナリデータとして保存（標準 QR 互換）
    if (_fileData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ファイルを選択してください')));
      return;
    }
    if (_fileData!.length > AppConstants.qrMaxTextBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ファイルサイズが QR コード容量(${_formatSize(AppConstants.qrMaxTextBytes)})を超えています',
          ),
        ),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final repo = ref.read(qrRepositoryProvider);
      final dbId = ref.read(currentDatabaseIdProvider);
      final entry = await repo.createEntry(
        name: name,
        data: _fileData!,
        chunkCount: 1,
        isTextMode: false,
        databaseId: dbId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QRコードを生成しました')));
      context.router.replace(DetailRoute(entryId: entry.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('生成に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// QR コードデータなしでメタデータのみのエントリを作成する。
  Future<void> _createWithoutQr() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称を入力してください')));
      return;
    }

    setState(() => _generating = true);
    try {
      final repo = ref.read(qrRepositoryProvider);
      final dbId = ref.read(currentDatabaseIdProvider);
      final entry = await repo.createEntry(
        name: name,
        data: Uint8List(0),
        chunkCount: 0,
        isTextMode: true,
        databaseId: dbId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エントリを作成しました（QRコード未登録）')));
      context.router.replace(DetailRoute(entryId: entry.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('作成に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
