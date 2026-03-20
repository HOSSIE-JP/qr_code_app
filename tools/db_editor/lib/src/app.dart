import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_shared/qr_shared.dart';

import 'editor_state.dart';
import 'io/editor_file_service.dart';

final editorStateProvider =
    NotifierProvider<EditorStateNotifier, EditorDocument>(
      EditorStateNotifier.new,
    );

/// DB Editor のアプリルート。
class DbEditorApp extends StatelessWidget {
  const DbEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _DbEditorMaterialApp());
  }
}

/// アプリ全体のテーマとホーム画面を定義する MaterialApp。
class _DbEditorMaterialApp extends StatelessWidget {
  const _DbEditorMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR DB Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      home: const _EditorPage(),
    );
  }
}

/// 外部ファイルの読み書きとプレビュー編集を提供するメイン画面。
class _EditorPage extends ConsumerWidget {
  const _EditorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(editorStateProvider);
    final notifier = ref.read(editorStateProvider.notifier);
    final selected = notifier.selectedEntry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR DB Editor'),
        actions: [
          TextButton.icon(
            onPressed: () => _openAny(context, notifier),
            icon: const Icon(Icons.folder_open),
            label: const Text('開く'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _saveAny(context, document, notifier),
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'template_xlsx',
                child: Text('Excel 雛形を生成'),
              ),
              PopupMenuItem<String>(
                value: 'template_ods',
                child: Text('ODS 雛形を生成'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'template_xlsx') {
                await _createTemplate(context, ods: false);
              } else if (value == 'template_ods') {
                await _createTemplate(context, ods: true);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.description),
                  SizedBox(width: 4),
                  Text('雛形'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'フィルタ',
                            hintText: '名前・説明・ID で検索',
                          ),
                          onChanged: notifier.updateFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SortButton(
                        icon: Icons.sort_by_alpha,
                        label: '名前',
                        onTap: () => notifier.updateSort(EntrySortField.name),
                      ),
                      const SizedBox(width: 8),
                      _SortButton(
                        icon: Icons.update,
                        label: '更新日',
                        onTap: () =>
                            notifier.updateSort(EntrySortField.updatedAt),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _EntryTable(
                    selectedEntryId: selected?.id,
                    onSelect: notifier.selectEntry,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected == null
                ? const Center(child: Text('左の一覧からエントリを選択してください。'))
                : _EntryDetailPanel(
                    key: ValueKey(selected.id),
                    entry: selected,
                    categories: document.categories,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'source: ${document.sourcePath ?? '-'}  |  entries: ${document.entries.length}  |  tags: ${document.tags.length}  |  categories: ${document.categories.length}  |  dirty: ${document.isDirty}',
        ),
      ),
    );
  }

  Future<void> _openAny(
    BuildContext context,
    EditorStateNotifier notifier,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'qrdb',
        'qrjson',
        'json',
        'xlsx',
        'ods',
        'csv',
        'yaml',
        'yml',
      ],
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.single.path;
    if (path == null) {
      return;
    }

    try {
      final document = await EditorFileService.loadFromPath(path);
      notifier.replaceDocument(document);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('読み込みに失敗しました: $error')));
    }
  }

  Future<void> _saveAny(
    BuildContext context,
    EditorDocument document,
    EditorStateNotifier notifier,
  ) async {
    final extension = _preferredExtension(document.sourcePath);
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '編集データを保存',
      fileName: 'edited_data$extension',
      type: FileType.custom,
      allowedExtensions: const [
        'qrdb',
        'qrjson',
        'json',
        'xlsx',
        'ods',
        'csv',
        'yaml',
        'yml',
      ],
    );
    if (savePath == null) {
      return;
    }

    final normalizedPath = _ensureExtension(savePath, extension);
    try {
      await EditorFileService.saveToPath(normalizedPath, document);
      notifier.markSaved(normalizedPath);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存しました: $normalizedPath')));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
    }
  }

  Future<void> _createTemplate(
    BuildContext context, {
    required bool ods,
  }) async {
    final extension = ods ? '.ods' : '.xlsx';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: ods ? 'ODS 雛形を保存' : 'Excel 雛形を保存',
      fileName: ods ? 'qr_template.ods' : 'qr_template.xlsx',
      type: FileType.custom,
      allowedExtensions: [extension.replaceFirst('.', '')],
    );
    if (path == null) {
      return;
    }

    final normalizedPath = _ensureExtension(path, extension);
    try {
      await EditorFileService.createTemplate(
        filePath: normalizedPath,
        ods: ods,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('雛形を生成しました: $normalizedPath')));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('雛形生成に失敗しました: $error')));
    }
  }

  String _preferredExtension(String? sourcePath) {
    if (sourcePath == null) {
      return '.qrjson';
    }
    final ext = p.extension(sourcePath).toLowerCase();
    if (ext.isEmpty) {
      return '.qrjson';
    }
    return ext;
  }

  String _ensureExtension(String path, String extension) {
    if (p.extension(path).isNotEmpty) {
      return path;
    }
    return '$path$extension';
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _EntryTable extends ConsumerWidget {
  const _EntryTable({required this.selectedEntryId, required this.onSelect});

  final String? selectedEntryId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(editorStateProvider);
    final notifier = ref.read(editorStateProvider.notifier);
    final entries = notifier.visibleEntries;

    return SingleChildScrollView(
      child: DataTable(
        sortAscending: document.ascending,
        columns: const [
          DataColumn(label: Text('名前')),
          DataColumn(label: Text('サイズ')),
          DataColumn(label: Text('更新日')),
        ],
        rows: [
          for (final entry in entries)
            DataRow(
              selected: selectedEntryId == entry.id,
              onSelectChanged: (_) => onSelect(entry.id),
              cells: [
                DataCell(Text(entry.name)),
                DataCell(Text('${entry.dataSize} bytes')),
                DataCell(Text(entry.updatedAt.toLocal().toString())),
              ],
            ),
        ],
      ),
    );
  }
}

class _EntryDetailPanel extends ConsumerWidget {
  const _EntryDetailPanel({
    super.key,
    required this.entry,
    required this.categories,
  });

  final QrEntryModel entry;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          Text('詳細プレビュー', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: entry.name,
            decoration: const InputDecoration(labelText: '名前'),
            onChanged: (value) => notifier.updateSelectedEntry(name: value),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: entry.description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '説明'),
            onChanged: (value) =>
                notifier.updateSelectedEntry(description: value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: entry.categoryId,
            decoration: const InputDecoration(labelText: 'カテゴリ'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('なし')),
              for (final category in categories)
                DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: (value) =>
                notifier.updateSelectedEntry(categoryId: value),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: entry.isTextMode,
            title: const Text('テキストモード'),
            onChanged: (value) =>
                notifier.updateSelectedEntry(isTextMode: value),
          ),
          SwitchListTile(
            value: entry.isFavorite,
            title: const Text('お気に入り'),
            onChanged: (value) =>
                notifier.updateSelectedEntry(isFavorite: value),
          ),
          const SizedBox(height: 8),
          Text('QR データサイズ: ${entry.dataSize} bytes'),
          const SizedBox(height: 8),
          _ThumbnailDropZone(
            thumbnailBytes: entry.thumbnail,
            onPicked: notifier.setSelectedThumbnail,
          ),
          const SizedBox(height: 16),
          _QrPreview(entry: entry),
        ],
      ),
    );
  }
}

class _ThumbnailDropZone extends StatefulWidget {
  const _ThumbnailDropZone({
    required this.thumbnailBytes,
    required this.onPicked,
  });

  final Uint8List? thumbnailBytes;
  final ValueChanged<Uint8List?> onPicked;

  @override
  State<_ThumbnailDropZone> createState() => _ThumbnailDropZoneState();
}

class _ThumbnailDropZoneState extends State<_ThumbnailDropZone> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('サムネイル', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (details) async {
            setState(() => _dragging = false);
            if (details.files.isEmpty) {
              return;
            }
            final bytes = await details.files.first.readAsBytes();
            widget.onPicked(bytes);
          },
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: _dragging
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.thumbnailBytes == null
                ? const Center(child: Text('画像をドロップ、または下のボタンから選択'))
                : Image.memory(widget.thumbnailBytes!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  withData: true,
                );
                if (result == null || result.files.isEmpty) {
                  return;
                }
                final file = result.files.first;
                final bytes =
                    file.bytes ??
                    (file.path != null
                        ? await File(file.path!).readAsBytes()
                        : null);
                if (bytes != null) {
                  widget.onPicked(bytes);
                }
              },
              icon: const Icon(Icons.image),
              label: const Text('画像を選択'),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onPicked(null),
              icon: const Icon(Icons.clear),
              label: const Text('クリア'),
            ),
          ],
        ),
      ],
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.entry});

  final QrEntryModel entry;

  @override
  Widget build(BuildContext context) {
    if (entry.originalData.isEmpty) {
      return const Text('QRデータ未登録');
    }

    final data = entry.isTextMode
        ? utf8.decode(entry.originalData, allowMalformed: true)
        : base64Encode(entry.originalData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QRプレビュー', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: QrImageView(data: data, size: 180),
        ),
      ],
    );
  }
}
