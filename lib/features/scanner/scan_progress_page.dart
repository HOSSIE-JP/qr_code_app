import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/qr_data_type_utils.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../widgets/tag_chips.dart';

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
  final _tagController = TextEditingController();
  final List<String> _selectedTagIds = <String>[];
  Uint8List? _thumbnail;
  late bool _isTextMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _buildDefaultEntryName();
    _nameController.addListener(_onFormChanged);
    _descController.addListener(_onFormChanged);
    _isTextMode = widget.isTextMode;
    if (_isTextMode) {
      final text = _decodeAsUtf8(widget.scannedData);
      if (text != null && text.isNotEmpty) {
        _descController.text = text;
      }
    } else if (QrDataTypeUtils.isLikelyText(widget.scannedData)) {
      _isTextMode = true;
      final text = _decodeAsUtf8(widget.scannedData);
      if (text != null && text.isNotEmpty) {
        _descController.text = text;
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _descController.removeListener(_onFormChanged);
    _nameController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 入力変更時に suffix アイコン表示を更新する。
  void _onFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTagsAsync = ref.watch(allTagsProvider);

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
                          _isTextMode ? Icons.text_fields : Icons.qr_code_2,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isTextMode ? 'テキストQRコード' : 'バイナリQRコード',
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
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.text_fields),
                          label: Text('テキスト'),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.data_array),
                          label: Text('バイナリ'),
                        ),
                      ],
                      selected: <bool>{_isTextMode},
                      onSelectionChanged: (values) {
                        final selected = values.first;
                        setState(() => _isTextMode = selected);
                        if (selected && _descController.text.trim().isEmpty) {
                          final text = _decodeAsUtf8(widget.scannedData);
                          if (text != null && text.isNotEmpty) {
                            _descController.text = text;
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('サムネイル', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _thumbnail != null
                      ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text('サムネイル', style: theme.textTheme.bodySmall),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('保存情報', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '名称 *',
                hintText: 'QRコードの名前を入力',
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        tooltip: '入力をクリア',
                        icon: const Icon(Icons.clear),
                        onPressed: () => _nameController.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: '説明・メモ',
                hintText: '説明やメモを入力（任意）',
                suffixIcon: _descController.text.isNotEmpty
                    ? IconButton(
                        tooltip: '入力をクリア',
                        icon: const Icon(Icons.clear),
                        onPressed: () => _descController.clear(),
                      )
                    : null,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text('タグ', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            allTagsAsync.when(
              data: (tags) => TagChips(
                tags: tags,
                selectedTagIds: _selectedTagIds,
                selectable: true,
                maxHeight: 140,
                onTagToggled: (tagId) {
                  setState(() {
                    if (_selectedTagIds.contains(tagId)) {
                      _selectedTagIds.remove(tagId);
                    } else {
                      _selectedTagIds.add(tagId);
                    }
                  });
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
              error: (_, _) => const Text('タグの読み込みに失敗しました'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: '新しいタグ',
                      hintText: 'タグ名を入力',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _saving ? null : _addTag,
                  icon: const Icon(Icons.add),
                ),
              ],
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
        isTextMode: _isTextMode,
        thumbnail: _thumbnail,
        tagIds: _selectedTagIds,
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

  /// 新規登録時に使うデフォルト名称を返す。
  ///
  /// 形式: yyyy/MM/dd HH:mm:ss
  String _buildDefaultEntryName() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute:$second';
  }

  /// スキャンされたデータのプレビュー文字列を返す。
  ///
  /// テキストモードの場合は UTF-8 文字列としてそのまま表示し、
  /// バイナリモードの場合は可読テキスト判定後、不可ならヘックスダンプを表示する。
  String _dataPreview() {
    // テキストモードの場合は UTF-8 として直接表示
    if (_isTextMode) {
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

  /// サムネイル画像を選択し、トリミング画面で加工して設定する。
  Future<void> _pickThumbnail() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_thumbnail != null)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('サムネイルを削除'),
                onTap: () {
                  setState(() => _thumbnail = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 1024);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    final cropped = await context.router.push<Uint8List>(
      ThumbnailCropRoute(imageBytes: bytes),
    );
    if (cropped != null) {
      setState(() => _thumbnail = cropped);
    }
  }

  /// 新しいタグを作成し、作成直後に選択状態へ追加する。
  Future<void> _addTag() async {
    final name = _tagController.text.trim();
    if (name.isEmpty) return;

    final dbId = ref.read(currentDatabaseIdProvider);
    final tag = await ref
        .read(tagRepositoryProvider)
        .createTag(name: name, databaseId: dbId);

    if (!mounted) return;
    setState(() {
      if (!_selectedTagIds.contains(tag.id)) {
        _selectedTagIds.add(tag.id);
      }
      _tagController.clear();
    });
    ref.invalidate(allTagsProvider);
  }

  /// UTF-8 として正しく読める場合のみ文字列を返す。
  String? _decodeAsUtf8(Uint8List data) {
    try {
      return utf8.decode(data);
    } on FormatException {
      return null;
    }
  }
}
