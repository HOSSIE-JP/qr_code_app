import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/qr_entry_model.dart';
import '../../providers/providers.dart';
import 'widgets/name_input_dialog.dart';

/// アプリの設定ページ。
///
/// データベース管理（新規作成・リネーム・削除）、タグ管理（リネーム・削除）、
/// アプリ情報を表示する。
@RoutePage()
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databasesAsync = ref.watch(allDatabasesProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final appVersionLabelAsync = ref.watch(appVersionLabelProvider);
    final currentDbId = ref.watch(currentDatabaseIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionHeader(title: '表示設定'),
          const _QrViewerDefaultSizeTile(),
          const _QrGenerationAdvancedTile(),
          const Divider(),

          // --- データベース管理 ---
          const _SectionHeader(title: 'データベース管理'),
          databasesAsync.when(
            data: (databases) => Column(
              children: [
                for (final db in databases)
                  _DatabaseTile(db: db, isCurrent: db.id == currentDbId),
                _AddDatabaseTile(),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const ListTile(
              leading: Icon(Icons.error_outline),
              title: Text('データベースを読み込めませんでした'),
            ),
          ),
          const Divider(),

          // --- カテゴリ管理 ---
          const _SectionHeader(title: 'カテゴリ管理'),
          categoriesAsync.when(
            data: (categories) => _CategorySection(categories: categories),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const ListTile(
              leading: Icon(Icons.error_outline),
              title: Text('カテゴリを読み込めませんでした'),
            ),
          ),
          const Divider(),

          // --- タグ管理 ---
          const _SectionHeader(title: 'タグ管理'),
          tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.label_off_outlined),
                  title: Text('タグがありません'),
                  subtitle: Text('エントリ編集画面からタグを追加できます'),
                );
              }
              return Column(
                children: [for (final tag in tags) _TagTile(tag: tag)],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const ListTile(
              leading: Icon(Icons.error_outline),
              title: Text('タグを読み込めませんでした'),
            ),
          ),
          const Divider(),

          // --- アプリ情報 ---
          const _SectionHeader(title: 'アプリ情報'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('バージョン'),
            subtitle: appVersionLabelAsync.when(
              data: (value) => Text(value),
              loading: () => const Text('読み込み中...'),
              error: (_, _) => const Text('不明'),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.qr_code_2),
            title: Text('プリQR'),
            subtitle: Text('任意のデータをQRコードに変換・管理するアプリ'),
          ),
        ],
      ),
    );
  }
}

/// カテゴリ管理セクション本体。
class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (categories.isEmpty)
          const ListTile(
            leading: Icon(Icons.folder_open),
            title: Text('カテゴリがありません'),
            subtitle: Text('下のボタンからカテゴリを作成してください'),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) async {
              final currentDbId = ref.read(currentDatabaseIdProvider);
              final list = [...categories];
              if (newIndex > oldIndex) newIndex -= 1;
              final moved = list.removeAt(oldIndex);
              list.insert(newIndex, moved);
              await ref
                  .read(qrRepositoryProvider)
                  .reorderCategories(
                    currentDbId,
                    list.map((e) => e.id).toList(),
                  );
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                key: ValueKey(category.id),
                leading: const Icon(Icons.drag_handle),
                title: Text(category.name),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'rename':
                        await _rename(context, ref, category);
                        return;
                      case 'delete':
                        await _delete(context, ref, category);
                        return;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('名前を変更')),
                    PopupMenuItem(value: 'delete', child: Text('削除')),
                  ],
                ),
              );
            },
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('新しいカテゴリを作成'),
          onTap: () => _create(context, ref),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const NameInputDialog(
        title: '新しいカテゴリ',
        label: 'カテゴリ名',
        actionLabel: '作成',
      ),
    );
    if (name == null || name.isEmpty) return;
    final dbId = ref.read(currentDatabaseIdProvider);
    await ref
        .read(qrRepositoryProvider)
        .createCategory(name: name, databaseId: dbId);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => NameInputDialog(
        title: 'カテゴリ名の変更',
        label: 'カテゴリ名',
        actionLabel: '変更',
        initialText: category.name,
      ),
    );
    if (newName == null || newName.isEmpty || newName == category.name) return;
    await ref
        .read(qrRepositoryProvider)
        .updateCategory(id: category.id, name: newName);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリ削除'),
        content: Text('「${category.name}」を削除しますか？'),
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
    if (confirmed != true) return;
    await ref.read(qrRepositoryProvider).deleteCategory(category.id);
  }
}

/// データベース一覧の各行。リネーム・削除が可能。
class _DatabaseTile extends ConsumerWidget {
  const _DatabaseTile({required this.db, required this.isCurrent});

  final QrDatabaseModel db;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDefault = db.id == 'default';

    return ListTile(
      leading: Icon(
        isCurrent ? Icons.check_circle : Icons.storage_outlined,
        color: isCurrent ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(db.name),
      subtitle: isCurrent ? const Text('使用中') : null,
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'rename':
              await _rename(context, ref);
              return;
            case 'delete':
              await _delete(context, ref);
              return;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Text('名前を変更')),
          if (!isDefault)
            const PopupMenuItem(value: 'delete', child: Text('削除')),
        ],
      ),
    );
  }

  /// データベース名を変更するダイアログ。
  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => NameInputDialog(
        title: 'データベース名の変更',
        label: 'データベース名',
        actionLabel: '変更',
        initialText: db.name,
      ),
    );

    if (newName == null || newName.isEmpty || newName == db.name) return;
    await ref
        .read(qrRepositoryProvider)
        .updateDatabase(id: db.id, name: newName);
  }

  /// データベースを削除する確認ダイアログ。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データベースの削除'),
        content: Text(
          '「${db.name}」を削除しますか？\n'
          '配下のエントリとタグもすべて削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final currentDbId = ref.read(currentDatabaseIdProvider);
    await ref.read(qrRepositoryProvider).deleteDatabase(db.id);
    // 削除した DB が選択中だった場合はデフォルトに切替
    if (currentDbId == db.id) {
      ref.read(currentDatabaseIdProvider.notifier).select('default');
    }
  }
}

/// データベースを新規作成する行。
class _AddDatabaseTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: const Text('新しいデータベースを作成'),
      onTap: () => _create(context, ref),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const NameInputDialog(
        title: '新しいデータベース',
        label: 'データベース名',
        actionLabel: '作成',
      ),
    );

    if (name == null || name.isEmpty) return;
    await ref.read(qrRepositoryProvider).createDatabase(name: name);
  }
}

/// タグ一覧の各行。リネーム・削除が可能。
class _TagTile extends ConsumerWidget {
  const _TagTile({required this.tag});

  final TagModel tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(tag.color),
        radius: 14,
        child: const Icon(Icons.label, size: 16, color: Colors.white),
      ),
      title: Text(tag.name),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'rename':
              await _rename(context, ref);
              return;
            case 'delete':
              await _delete(context, ref);
              return;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Text('名前を変更')),
          const PopupMenuItem(value: 'delete', child: Text('削除')),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => NameInputDialog(
        title: 'タグ名の変更',
        label: 'タグ名',
        actionLabel: '変更',
        initialText: tag.name,
      ),
    );

    if (newName == null || newName.isEmpty || newName == tag.name) return;
    await ref.read(tagRepositoryProvider).updateTagName(tag.id, newName);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグの削除'),
        content: Text(
          '「${tag.name}」を削除しますか？\n'
          'エントリからこのタグの紐付きが解除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(tagRepositoryProvider).deleteTag(tag.id);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// QR 表示画面の初期サイズを設定するタイル。
class _QrViewerDefaultSizeTile extends ConsumerWidget {
  const _QrViewerDefaultSizeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(qrViewerDefaultSizeProvider);
    return ListTile(
      leading: const Icon(Icons.straighten),
      title: const Text('QR 初期表示サイズ'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${size.round()} px'),
          Slider(
            value: size,
            min: 120,
            max: 500,
            divisions: 38,
            label: '${size.round()}px',
            onChanged: (value) {
              ref.read(qrViewerDefaultSizeProvider.notifier).setSize(value);
            },
          ),
        ],
      ),
    );
  }
}

/// QR 生成・描画の高度設定をまとめたアコーディオン。
class _QrGenerationAdvancedTile extends ConsumerWidget {
  const _QrGenerationAdvancedTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(qrGenerationSettingsProvider);
    final notifier = ref.read(qrGenerationSettingsProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: const Text('高度な設定（QR生成）'),
        subtitle: Text(
          '誤り訂正: ${_labelFor(config.errorLevel)} / '
          '余白: ${config.padding.round()}px / '
          'ギャップレス: ${config.gapless ? 'ON' : 'OFF'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(
            children: [
              const Expanded(child: Text('誤り訂正レベル')),
              DropdownButton<QrGenerationErrorLevel>(
                value: config.errorLevel,
                onChanged: (value) {
                  if (value == null) return;
                  notifier.setErrorLevel(value);
                },
                items: QrGenerationErrorLevel.values
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(_labelFor(level)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: config.gapless,
            contentPadding: EdgeInsets.zero,
            title: const Text('ギャップレス描画'),
            subtitle: const Text('モジュール間の隙間を補間して表示します'),
            onChanged: notifier.setGapless,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('余白'),
              const SizedBox(width: 8),
              Text('${config.padding.round()} px'),
            ],
          ),
          Slider(
            value: config.padding,
            min: 0,
            max: 24,
            divisions: 24,
            label: '${config.padding.round()}px',
            onChanged: notifier.setPadding,
          ),
        ],
      ),
    );
  }

  /// UI 表示用の誤り訂正レベル名。
  String _labelFor(QrGenerationErrorLevel level) {
    switch (level) {
      case QrGenerationErrorLevel.low:
        return '低 (L)';
      case QrGenerationErrorLevel.medium:
        return '中 (M)';
      case QrGenerationErrorLevel.quartile:
        return '高 (Q)';
      case QrGenerationErrorLevel.high:
        return '最高 (H)';
    }
  }
}
