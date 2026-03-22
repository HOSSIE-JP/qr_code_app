import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_shared/qr_shared.dart';

import 'editor_state.dart';
import 'io/editor_file_service.dart';
import 'io/web_download.dart';

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
            onPressed: notifier.addEntry,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('新規エントリ'),
          ),
          const SizedBox(width: 8),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 920;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                labelText: 'フィルタ',
                                hintText: '名前・説明・ID で検索',
                              ),
                              onChanged: notifier.updateFilter,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SortButton(
                                  icon: Icons.sort_by_alpha,
                                  label: '名前',
                                  onTap: () =>
                                      notifier.updateSort(EntrySortField.name),
                                ),
                                _SortButton(
                                  icon: Icons.update,
                                  label: '更新日',
                                  onTap: () => notifier.updateSort(
                                    EntrySortField.updatedAt,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
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
                            onTap: () =>
                                notifier.updateSort(EntrySortField.name),
                          ),
                          const SizedBox(width: 8),
                          _SortButton(
                            icon: Icons.update,
                            label: '更新日',
                            onTap: () =>
                                notifier.updateSort(EntrySortField.updatedAt),
                          ),
                        ],
                      );
                    },
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
            child: _EditorRightPane(
              selected: selected,
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
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    try {
      final file = result.files.single;
      final document = kIsWeb
          ? await EditorFileService.loadFromBytes(
              fileName: file.name,
              bytes:
                  file.bytes ??
                  (throw const FormatException('ブラウザからファイルデータを取得できませんでした。')),
            )
          : await EditorFileService.loadFromPath(
              file.path ?? (throw const FormatException('ファイルパスを取得できませんでした。')),
            );
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
    final format = await _selectSaveFormat(context, document.sourcePath);
    if (format == null) {
      return;
    }

    if (kIsWeb) {
      try {
        final bytes = await EditorFileService.exportAsBytes(
          extension: '.${format.extension}',
          document: document,
        );
        downloadBytesOnWeb(
          fileName: 'edited_data.${format.extension}',
          bytes: bytes,
          mimeType: format.mimeType,
        );
        notifier.markSaved('edited_data.${format.extension}');
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ブラウザへ保存を開始しました。')));
      } on Object catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
      }
      return;
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '編集データを保存',
      fileName: 'edited_data.${format.extension}',
      type: FileType.custom,
      allowedExtensions: [format.extension],
    );
    if (savePath == null) {
      return;
    }

    try {
      await EditorFileService.saveToPath(savePath, document);
      notifier.markSaved(savePath);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存しました: $savePath')));
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
    if (kIsWeb) {
      try {
        final bytes = await EditorFileService.createTemplateBytes(ods: ods);
        downloadBytesOnWeb(
          fileName: ods ? 'qr_template.ods' : 'qr_template.xlsx',
          bytes: bytes,
          mimeType: ods
              ? 'application/vnd.oasis.opendocument.spreadsheet'
              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('雛形ファイルのダウンロードを開始しました。')));
      } on Object catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('雛形生成に失敗しました: $error')));
      }
      return;
    }

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

    try {
      await EditorFileService.createTemplate(filePath: path, ods: ods);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('雛形を生成しました: $path')));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('雛形生成に失敗しました: $error')));
    }
  }

  /// 保存形式を選択するダイアログを表示する。
  Future<_SaveFormat?> _selectSaveFormat(
    BuildContext context,
    String? sourcePath,
  ) async {
    final sourceExt = p.extension(sourcePath ?? '').toLowerCase();
    final availableFormats = _SaveFormat.availableOnCurrentPlatform;
    final initial = availableFormats.firstWhere(
      (value) => '.${value.extension}' == sourceExt,
      orElse: () => _SaveFormat.qrjson,
    );

    var selected = initial;
    return showDialog<_SaveFormat>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('保存形式を選択'),
              content: DropdownButtonFormField<_SaveFormat>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: '形式'),
                items: [
                  for (final format in availableFormats)
                    DropdownMenuItem<_SaveFormat>(
                      value: format,
                      child: Text(format.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setLocalState(() => selected = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('次へ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 保存時に選択可能なフォーマット。
enum _SaveFormat {
  qrdb('QR DB (*.qrdb)', 'qrdb'),
  qrjson('QR JSON (*.qrjson)', 'qrjson'),
  json('JSON (*.json)', 'json'),
  xlsx('Excel (*.xlsx)', 'xlsx'),
  ods('ODS (*.ods)', 'ods'),
  csv('CSV (*.csv)', 'csv'),
  yaml('YAML (*.yaml)', 'yaml');

  const _SaveFormat(this.label, this.extension);

  final String label;
  final String extension;

  String get mimeType {
    switch (this) {
      case _SaveFormat.qrdb:
        return 'application/zip';
      case _SaveFormat.qrjson:
      case _SaveFormat.json:
        return 'application/json';
      case _SaveFormat.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case _SaveFormat.ods:
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case _SaveFormat.csv:
        return 'text/csv';
      case _SaveFormat.yaml:
        return 'application/yaml';
    }
  }

  static List<_SaveFormat> get availableOnCurrentPlatform {
    if (!kIsWeb) {
      return _SaveFormat.values;
    }
    return const <_SaveFormat>[
      _SaveFormat.qrdb,
      _SaveFormat.qrjson,
      _SaveFormat.json,
      _SaveFormat.xlsx,
      _SaveFormat.ods,
    ];
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
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 760),
        child: DataTable(
          sortAscending: document.ascending,
          columns: const [
            DataColumn(label: Text('名前')),
            DataColumn(label: Text('★')),
            DataColumn(label: Text('T')),
            DataColumn(label: Text('サイズ')),
            DataColumn(label: Text('更新日')),
            DataColumn(label: Text('削除')),
          ],
          rows: [
            for (final entry in entries)
              DataRow(
                selected: selectedEntryId == entry.id,
                onSelectChanged: (_) => onSelect(entry.id),
                cells: [
                  DataCell(Text(entry.name)),
                  DataCell(
                    Checkbox(
                      value: entry.isFavorite,
                      onChanged: (value) {
                        if (value == null) return;
                        notifier.setEntryFavorite(entry.id, value);
                      },
                    ),
                  ),
                  DataCell(
                    Checkbox(
                      value: entry.isTextMode,
                      onChanged: (value) {
                        if (value == null) return;
                        notifier.setEntryTextMode(entry.id, value);
                      },
                    ),
                  ),
                  DataCell(Text('${entry.dataSize} bytes')),
                  DataCell(Text(entry.updatedAt.toLocal().toString())),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'エントリを削除',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('エントリ削除'),
                            content: Text('「${entry.name}」を削除しますか？'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('キャンセル'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('削除'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          notifier.deleteEntry(entry.id);
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 右側ペインを「エントリ詳細」と「分類編集」の2タブで表示する。
class _EditorRightPane extends StatelessWidget {
  const _EditorRightPane({required this.selected, required this.categories});

  final QrEntryModel? selected;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.description), text: 'エントリ詳細'),
              Tab(icon: Icon(Icons.label), text: '分類編集'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                selected == null
                    ? const Center(child: Text('左の一覧からエントリを選択してください。'))
                    : _EntryDetailPanel(
                        key: ValueKey(selected!.id),
                        entry: selected!,
                        categories: categories,
                      ),
                const _TaxonomyEditorPanel(),
              ],
            ),
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
          Text('タグ割り当て', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _EntryTagSelector(entry: entry),
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

/// 選択中エントリにタグを割り当てる UI。
class _EntryTagSelector extends ConsumerWidget {
  const _EntryTagSelector({required this.entry});

  final QrEntryModel entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(editorStateProvider);
    final notifier = ref.read(editorStateProvider.notifier);
    if (document.tags.isEmpty) {
      return const Text('タグがありません。下の入力欄から追加してください。');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in document.tags)
          FilterChip(
            label: Text(tag.name),
            selected: entry.tags.any((value) => value.id == tag.id),
            onSelected: (_) => notifier.toggleTagForSelectedEntry(tag.id),
          ),
      ],
    );
  }
}

/// タグ/カテゴリをまとめて編集する専用タブ。
class _TaxonomyEditorPanel extends StatelessWidget {
  const _TaxonomyEditorPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _CategoryEditorPanel(),
        SizedBox(height: 16),
        _TagEditorPanel(),
      ],
    );
  }
}

/// カテゴリの新規追加・名称変更・削除を行うパネル。
class _CategoryEditorPanel extends ConsumerStatefulWidget {
  const _CategoryEditorPanel();

  @override
  ConsumerState<_CategoryEditorPanel> createState() =>
      _CategoryEditorPanelState();
}

class _CategoryEditorPanelState extends ConsumerState<_CategoryEditorPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(editorStateProvider);
    final notifier = ref.read(editorStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('カテゴリ編集', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '新規カテゴリ名',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                notifier.addCategory(_controller.text);
                _controller.clear();
              },
              icon: const Icon(Icons.add),
              label: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (document.categories.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in document.categories)
                InputChip(
                  label: Text(category.name),
                  onPressed: () async {
                    final renamed = await _showRenameDialog(
                      context,
                      category.name,
                    );
                    if (renamed == null) return;
                    notifier.renameCategory(category.id, renamed);
                  },
                  onDeleted: () => notifier.deleteCategory(category.id),
                ),
            ],
          ),
      ],
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    try {
      return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('カテゴリ名を変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'カテゴリ名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

/// タグの新規追加・リネーム・削除を行うパネル。
class _TagEditorPanel extends ConsumerStatefulWidget {
  const _TagEditorPanel();

  @override
  ConsumerState<_TagEditorPanel> createState() => _TagEditorPanelState();
}

class _TagEditorPanelState extends ConsumerState<_TagEditorPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(editorStateProvider);
    final notifier = ref.read(editorStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('タグ編集', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '新規タグ名',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                notifier.addTag(_controller.text);
                _controller.clear();
              },
              icon: const Icon(Icons.add),
              label: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (document.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in document.tags)
                InputChip(
                  label: Text(tag.name),
                  onPressed: () async {
                    final renamed = await _showRenameDialog(context, tag.name);
                    if (renamed == null) return;
                    notifier.renameTag(tag.id, renamed);
                  },
                  onDeleted: () => notifier.deleteTag(tag.id),
                ),
            ],
          ),
      ],
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    try {
      return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('タグ名を変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'タグ名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
