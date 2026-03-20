import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/models/qr_entry_model.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../widgets/platform_utils.dart';
import '../../widgets/tag_chips.dart';

/// QR エントリの編集ページ。
///
/// 名称・説明・サムネイル・タグ・QR データを編集できる。
/// QR データはカメラまたは画像ファイルからの QR 読取で登録・変更できる。
/// サムネイルはカメラ撮影またはギャラリーから選択し、
/// [ThumbnailCropPage] でトリミングした後に設定される。
@RoutePage()
class EditPage extends ConsumerStatefulWidget {
  const EditPage({super.key, required this.entryId});

  final String entryId;

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  List<String> _selectedTagIds = [];
  String? _selectedCategoryId;
  Uint8List? _thumbnail;
  bool _isFavorite = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _initFromEntry(QrEntryModel entry) {
    if (_initialized) return;
    _nameController.text = entry.name;
    _descController.text = entry.description;
    _selectedTagIds = entry.tags.map((t) => t.id).toList();
    _selectedCategoryId = entry.categoryId;
    _thumbnail = entry.thumbnail;
    _isFavorite = entry.isFavorite;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(qrEntryByIdProvider(widget.entryId));
    final allTagsAsync = ref.watch(allTagsProvider);
    final allCategoriesAsync = ref.watch(allCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('編集'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(ref),
            child: const Text('保存'),
          ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('エントリが見つかりません'));
          }
          _initFromEntry(entry);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Center(
                  child: GestureDetector(
                    onTap: _pickThumbnail,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
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

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '名称 *'),
                ),
                const SizedBox(height: 16),
                allCategoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'カテゴリ'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('未分類'),
                      ),
                      for (final category in categories)
                        DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('お気に入り'),
                  secondary: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  value: _isFavorite,
                  onChanged: (v) => setState(() => _isFavorite = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: '説明・メモ',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  minLines: 3,
                ),
                const SizedBox(height: 24),

                // Tags section
                Text('タグ', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                allTagsAsync.when(
                  data: (tags) => TagChips(
                    tags: tags,
                    selectedTagIds: _selectedTagIds,
                    selectable: true,
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, e) => const Text('タグの読み込みに失敗しました'),
                ),
                const SizedBox(height: 12),
                // Add new tag
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
                      onPressed: _addTag,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // QR データセクション
                Text('QR データ', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildQrDataSection(entry, theme),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  /// QR データの状態表示と操作 UI。
  Widget _buildQrDataSection(QrEntryModel entry, ThemeData theme) {
    if (entry.hasQrData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QR 登録済み（${_formatSize(entry.dataSize)}）',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateQrData(entry),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QR を読み取って変更'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _clearQrData(entry.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      '削除',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'QR 未登録',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _updateQrData(entry),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR を読み取って登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// QR データをカメラまたは画像読取で更新する。
  ///
  /// カメラスキャン対応プラットフォームではカメラと画像の選択肢を提示し、
  /// Web 等ではギャラリー画像のみ利用できる。
  Future<void> _updateQrData(QrEntryModel entry) async {
    // 読取方法を選択
    final method = await showModalBottomSheet<_QrReadMethod>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCameraScanSupported)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで QR を読み取り'),
                onTap: () => Navigator.pop(context, _QrReadMethod.camera),
              ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('画像ファイルから QR を読み取り'),
              onTap: () => Navigator.pop(context, _QrReadMethod.image),
            ),
          ],
        ),
      ),
    );
    if (method == null || !mounted) return;

    Uint8List? scannedData;
    switch (method) {
      case _QrReadMethod.camera:
        scannedData = await _scanQrFromCamera();
      case _QrReadMethod.image:
        scannedData = await _scanQrFromImage();
    }

    if (scannedData == null || !mounted) return;

    try {
      await ref
          .read(qrRepositoryProvider)
          .updateQrData(id: entry.id, data: scannedData, isTextMode: true);
      ref.invalidate(qrEntryByIdProvider(widget.entryId));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR データを更新しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR データの更新に失敗しました: $e')));
    }
  }

  /// カメラで QR コードをスキャンして結果のバイト列を返す。
  ///
  /// スキャン結果を受け取るまでフルスクリーンのスキャナ画面を表示する。
  Future<Uint8List?> _scanQrFromCamera() async {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const _QrScannerSheet()),
    );
  }

  /// 画像ファイルから QR コードを読み取って結果のバイト列を返す。
  Future<Uint8List?> _scanQrFromImage() async {
    if (kIsWeb) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Web 環境では画像読み取りに対応していません')));
      return null;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final controller = MobileScannerController();
    try {
      final result = await controller.analyzeImage(image.path);
      if (result == null || result.barcodes.isEmpty) {
        if (!mounted) return null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('画像から QR コードを検出できませんでした')));
        return null;
      }
      final barcode = result.barcodes.first;
      // rawDecodedBytes があればそのまま使い、なければ rawValue を UTF-8 エンコード
      final rawDecoded = barcode.rawDecodedBytes;
      if (rawDecoded is DecodedBarcodeBytes) {
        return rawDecoded.bytes;
      } else if (rawDecoded is DecodedVisionBarcodeBytes) {
        return rawDecoded.bytes ?? rawDecoded.rawBytes;
      }
      final rawValue = barcode.rawValue;
      if (rawValue != null) {
        return Uint8List.fromList(utf8.encode(rawValue));
      }
      return null;
    } finally {
      controller.dispose();
    }
  }

  /// QR データを削除する確認ダイアログを表示。
  Future<void> _clearQrData(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR データの削除'),
        content: const Text('QR データを削除しますか？メタデータ（名前・説明・タグ等）は保持されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(qrRepositoryProvider).clearQrData(entryId);
      ref.invalidate(qrEntryByIdProvider(widget.entryId));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR データを削除しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR データの削除に失敗しました: $e')));
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

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

    // Navigate to crop page
    final cropped = await context.router.push<Uint8List>(
      ThumbnailCropRoute(imageBytes: bytes),
    );
    if (cropped != null) {
      setState(() => _thumbnail = cropped);
    }
  }

  Future<void> _addTag() async {
    final name = _tagController.text.trim();
    if (name.isEmpty) return;

    final tagRepo = ref.read(tagRepositoryProvider);
    final tag = await tagRepo.createTag(name: name);
    setState(() {
      if (!_selectedTagIds.contains(tag.id)) {
        _selectedTagIds.add(tag.id);
      }
    });
    _tagController.clear();
    ref.invalidate(allTagsProvider);
  }

  Future<void> _save(WidgetRef ref) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称を入力してください')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(qrRepositoryProvider)
          .updateEntry(
            id: widget.entryId,
            name: name,
            description: _descController.text.trim(),
            isFavorite: _isFavorite,
            categoryId: _selectedCategoryId,
            clearCategory: _selectedCategoryId == null,
            thumbnail: _thumbnail,
            tagIds: _selectedTagIds,
          );
      if (!mounted) return;
      ref.invalidate(qrEntryByIdProvider(widget.entryId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// QR 読取方法の選択肢。
enum _QrReadMethod { camera, image }

/// 編集ページ内で QR コードをカメラスキャンするためのフルスクリーンシート。
///
/// QR を検出すると [Navigator.pop] でバイト列を返す。
class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR コードを読み取り'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'フラッシュ',
          ),
        ],
      ),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    for (final barcode in capture.barcodes) {
      // rawDecodedBytes があればそのまま使い、なければ rawValue を UTF-8 エンコード
      Uint8List? data;
      final rawDecoded = barcode.rawDecodedBytes;
      if (rawDecoded is DecodedBarcodeBytes) {
        data = rawDecoded.bytes;
      } else if (rawDecoded is DecodedVisionBarcodeBytes) {
        data = rawDecoded.bytes ?? rawDecoded.rawBytes;
      } else if (barcode.rawValue != null) {
        data = Uint8List.fromList(utf8.encode(barcode.rawValue!));
      }
      if (data != null) {
        _detected = true;
        Navigator.of(context).pop(data);
        return;
      }
    }
  }
}
