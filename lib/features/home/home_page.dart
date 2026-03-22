import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_prefs.dart';
import '../../data/models/qr_entry_model.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../widgets/qr_entry_card.dart';
import '../../widgets/platform_utils.dart';

/// アプリのホーム画面。
///
/// DB 切替、ソート、グリッド/リスト表示、お気に入りセクション、
/// 長押しによるマルチ選択＋一括削除を提供する。
@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isGridView = true;
  bool _favoritesExpanded = true;

  @override
  void initState() {
    super.initState();
    if (AppPrefs.isInitialized) {
      _isGridView = AppPrefs.homeGridView;
    }
  }

  /// 選択中のエントリ ID。空なら通常モード。
  final Set<String> _selectedIds = {};

  /// true のとき選択モードでカテゴリ設定UIを表示する。
  bool _categoryEditMode = false;

  /// カテゴリアコーディオンの開閉状態。
  final Map<String, bool> _expandedCategories = {};

  /// 選択モードかどうか。
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  /// 選択モードを解除する。
  void _clearSelection() => setState(() => _selectedIds.clear());

  /// エントリの選択をトグルする。
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _categoryEditMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(qrEntriesProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(theme)
          : _buildNormalAppBar(),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(context);
          }
          final favorites = entries.where((e) => e.isFavorite).toList();
          final others = entries.where((e) => !e.isFavorite).toList();
          final categories = categoriesAsync.maybeWhen(
            data: (value) => value,
            orElse: () => const <CategoryModel>[],
          );
          return _buildBody(favorites, others, categories);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'データの読み込みに失敗しました',
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(qrEntriesProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ────────────────────────────────────────
  // AppBar
  // ────────────────────────────────────────

  /// 通常時の AppBar。DB 名表示（タップで切替）・ソート・検索・メニューを表示。
  PreferredSizeWidget _buildNormalAppBar() {
    final databasesAsync = ref.watch(allDatabasesProvider);
    final currentDbId = ref.watch(currentDatabaseIdProvider);
    final entries = ref
        .watch(qrEntriesProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <QrEntryModel>[],
        );
    final categories = ref
        .watch(allCategoriesProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <CategoryModel>[],
        );
    final hasExpandableSections = _hasExpandableSections(entries, categories);
    final allExpanded = _isAllAccordionExpanded(entries, categories);

    return AppBar(
      title: databasesAsync.when(
        data: (databases) {
          if (databases.isEmpty) {
            return const Text('QR Code Manager');
          }
          final exists = databases.any((db) => db.id == currentDbId);
          if (!exists) {
            // 保存済み ID が削除されていた場合は先頭 DB を選び直す。
            ref
                .read(currentDatabaseIdProvider.notifier)
                .select(databases.first.id);
          }
          final current = databases.firstWhere(
            (db) => db.id == currentDbId,
            orElse: () => databases.first,
          );
          // タイトルをタップすると DB 切替ダイアログを表示
          return GestureDetector(
            onTap: () => _showDatabaseSwitcher(databases, currentDbId),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(current.name, overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          );
        },
        loading: () => const Text('QR Code Manager'),
        error: (_, _) => const Text('QR Code Manager'),
      ),
      actions: [
        if (hasExpandableSections)
          IconButton(
            icon: Icon(allExpanded ? Icons.unfold_less : Icons.unfold_more),
            tooltip: allExpanded ? 'すべて閉じる' : 'すべて開く',
            onPressed: () {
              _setAllAccordionExpanded(!allExpanded, entries, categories);
            },
          ),
        _buildSortButton(),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: _isGridView ? 'リスト表示' : 'グリッド表示',
          onPressed: () {
            final next = !_isGridView;
            setState(() => _isGridView = next);
            if (AppPrefs.isInitialized) {
              AppPrefs.setHomeGridView(next);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '検索',
          onPressed: () => context.router.push(const SearchRoute()),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export':
                context.router.push(const ExportRoute());
                return;
              case 'import':
                context.router.push(const ImportRoute());
                return;
              case 'settings':
                context.router.push(const SettingsRoute());
                return;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.upload),
                title: Text('エクスポート'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('インポート'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('設定'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 開閉可能セクション（お気に入り/カテゴリ）が1つ以上あるか判定する。
  bool _hasExpandableSections(
    List<QrEntryModel> entries,
    List<CategoryModel> categories,
  ) {
    final hasFavorites = entries.any((entry) => entry.isFavorite);
    if (hasFavorites) return true;

    for (final category in categories) {
      final hasEntries = entries.any(
        (entry) => !entry.isFavorite && entry.categoryId == category.id,
      );
      if (hasEntries) return true;
    }
    return false;
  }

  /// すべてのアコーディオンが開いているか判定する。
  bool _isAllAccordionExpanded(
    List<QrEntryModel> entries,
    List<CategoryModel> categories,
  ) {
    final hasFavorites = entries.any((entry) => entry.isFavorite);
    if (hasFavorites && !_favoritesExpanded) return false;

    for (final category in categories) {
      final hasEntries = entries.any(
        (entry) => !entry.isFavorite && entry.categoryId == category.id,
      );
      if (!hasEntries) continue;
      if (!(_expandedCategories[category.id] ?? true)) {
        return false;
      }
    }

    return true;
  }

  /// お気に入りとカテゴリのアコーディオンを一括で開閉する。
  void _setAllAccordionExpanded(
    bool expanded,
    List<QrEntryModel> entries,
    List<CategoryModel> categories,
  ) {
    setState(() {
      if (entries.any((entry) => entry.isFavorite)) {
        _favoritesExpanded = expanded;
      }
      for (final category in categories) {
        final hasEntries = entries.any(
          (entry) => !entry.isFavorite && entry.categoryId == category.id,
        );
        if (!hasEntries) continue;
        _expandedCategories[category.id] = expanded;
      }
    });
  }

  /// データベース切替用のボトムシートを表示する。
  void _showDatabaseSwitcher(
    List<QrDatabaseModel> databases,
    String currentDbId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'データベース切替',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      this.context.router.push(const SettingsRoute());
                    },
                    child: const Text('管理'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 最大高さを制限してスクロール可能にする
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: databases.length,
                itemBuilder: (context, index) {
                  final db = databases[index];
                  final isSelected = db.id == currentDbId;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(db.name),
                    selected: isSelected,
                    onTap: () {
                      ref
                          .read(currentDatabaseIdProvider.notifier)
                          .select(db.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ソートボタン。現在のソート設定を反映しメニューで切替。
  Widget _buildSortButton() {
    final sortConfig = ref.watch(sortConfigProvider);
    return PopupMenuButton<SortField>(
      icon: const Icon(Icons.sort),
      tooltip: '並び替え',
      onSelected: (field) {
        ref.read(sortConfigProvider.notifier).setField(field);
      },
      itemBuilder: (context) => [
        for (final field in SortField.values)
          PopupMenuItem(
            value: field,
            child: Row(
              children: [
                if (sortConfig.field == field)
                  Icon(
                    sortConfig.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 18,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(_sortFieldLabel(field)),
              ],
            ),
          ),
      ],
    );
  }

  String _sortFieldLabel(SortField field) {
    return switch (field) {
      SortField.name => '名前',
      SortField.createdAt => '作成日',
      SortField.updatedAt => '更新日',
    };
  }

  /// 選択モード時の AppBar。選択数と一括削除ボタンを表示。
  PreferredSizeWidget _buildSelectionAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '選択解除',
        onPressed: _clearSelection,
      ),
      title: Text('${_selectedIds.length} 件選択中'),
      actions: [
        IconButton(
          icon: Icon(_categoryEditMode ? Icons.label : Icons.label_outline),
          tooltip: 'カテゴリ編集モード',
          onPressed: () {
            setState(() => _categoryEditMode = !_categoryEditMode);
            if (_categoryEditMode) {
              _showCategoryEditorForSelected();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: '選択したエントリを削除',
          onPressed: _confirmDeleteSelected,
        ),
      ],
    );
  }

  /// 選択中のエントリを削除する確認ダイアログを表示。
  Future<void> _confirmDeleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エントリの削除'),
        content: Text('$count 件のエントリを削除しますか？この操作は取り消せません。'),
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

    await ref.read(qrRepositoryProvider).deleteEntries(_selectedIds.toList());
    _clearSelection();
  }

  // ────────────────────────────────────────
  // ボディ
  // ────────────────────────────────────────

  /// お気に入りセクションとエントリ一覧を表示するボディ。
  Widget _buildBody(
    List<QrEntryModel> favorites,
    List<QrEntryModel> others,
    List<CategoryModel> categories,
  ) {
    final categorized = <String, List<QrEntryModel>>{};
    for (final category in categories) {
      categorized[category.id] = others
          .where((entry) => entry.categoryId == category.id)
          .toList();
    }
    final uncategorized = others
        .where((entry) => entry.categoryId == null)
        .toList();

    return CustomScrollView(
      slivers: [
        // お気に入りセクション（存在する場合のみ表示）
        if (favorites.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildFavoritesHeader(favorites.length)),
          if (_favoritesExpanded)
            (_isGridView
                ? _buildSliverGrid(favorites)
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildFavoriteItem(favorites[index]),
                        childCount: favorites.length,
                      ),
                    ),
                  )),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
        // カテゴリ別セクション
        for (final category in categories)
          ..._buildCategorySection(
            category,
            categorized[category.id] ?? const [],
          ),

        // 未分類エントリ
        if (uncategorized.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('未分類'),
            ),
          ),
          _isGridView
              ? _buildSliverGrid(uncategorized)
              : _buildSliverList(uncategorized),
        ],
        if (others.isEmpty && favorites.isNotEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('お気に入り以外のエントリはありません')),
          ),
      ],
    );
  }

  List<Widget> _buildCategorySection(
    CategoryModel category,
    List<QrEntryModel> entries,
  ) {
    if (entries.isEmpty) return const [];
    final expanded = _expandedCategories[category.id] ?? true;

    return [
      SliverPersistentHeader(
        pinned: expanded,
        delegate: _CategoryHeaderDelegate(
          categoryName: category.name,
          itemCount: entries.length,
          expanded: expanded,
          onTap: () {
            setState(() {
              _expandedCategories[category.id] = !expanded;
            });
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
      if (expanded)
        (_isGridView ? _buildSliverGrid(entries) : _buildSliverList(entries)),
    ];
  }

  /// お気に入りセクションのヘッダ。タップで折り畳みを切り替え。
  Widget _buildFavoritesHeader(int count) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _favoritesExpanded = !_favoritesExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text('お気に入り ($count)', style: theme.textTheme.titleSmall),
            const Spacer(),
            Icon(
              _favoritesExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ],
        ),
      ),
    );
  }

  /// お気に入りエントリの1行表示。選択モード対応。
  Widget _buildFavoriteItem(QrEntryModel entry) {
    final theme = Theme.of(context);
    final isSelected = _selectedIds.contains(entry.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(entry.id),
              )
            : _buildListThumbnail(entry, theme, size: 40),
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: entry.description.isNotEmpty
            ? Text(
                entry.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: _isSelectionMode
            ? null
            : IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                tooltip: 'お気に入り解除',
                onPressed: () async {
                  await ref.read(qrRepositoryProvider).toggleFavorite(entry.id);
                },
              ),
        onTap: _isSelectionMode
            ? () => _toggleSelection(entry.id)
            : () => context.router.push(DetailRoute(entryId: entry.id)),
        onLongPress: () => _toggleSelection(entry.id),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text('QRコードがありません', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'QRコードをスキャンするか、データからQRコードを生成しましょう',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────
  // グリッド / リスト
  // ────────────────────────────────────────

  Widget _buildSliverGrid(List<QrEntryModel> entries) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.crossAxisExtent > 900
            ? 4
            : constraints.crossAxisExtent > 600
            ? 3
            : 2;
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = entries[index];
              final isSelected = _selectedIds.contains(entry.id);
              return QrEntryCard(
                entry: entry,
                isSelected: isSelected,
                onTap: _isSelectionMode
                    ? () => _toggleSelection(entry.id)
                    : () => context.router.push(DetailRoute(entryId: entry.id)),
                onLongPress: () => _toggleSelection(entry.id),
                onFavoriteToggle: _isSelectionMode
                    ? null
                    : () async {
                        await ref
                            .read(qrRepositoryProvider)
                            .toggleFavorite(entry.id);
                      },
              );
            }, childCount: entries.length),
          ),
        );
      },
    );
  }

  Widget _buildSliverList(List<QrEntryModel> entries) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList.separated(
        itemCount: entries.length,
        separatorBuilder: (_, i) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final theme = Theme.of(context);
          final isSelected = _selectedIds.contains(entry.id);
          return Card(
            clipBehavior: Clip.antiAlias,
            color: isSelected ? theme.colorScheme.primaryContainer : null,
            child: ListTile(
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(entry.id),
                    )
                  : _buildListThumbnail(entry, theme, size: 48),
              title: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: entry.description.isNotEmpty
                  ? Text(
                      entry.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: _isSelectionMode
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
              onTap: _isSelectionMode
                  ? () => _toggleSelection(entry.id)
                  : () => context.router.push(DetailRoute(entryId: entry.id)),
              onLongPress: () => _toggleSelection(entry.id),
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────
  // FAB
  // ────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    if (!isCameraScanSupported) {
      return FloatingActionButton.extended(
        heroTag: 'generate',
        onPressed: () => context.router.push(const GeneratorRoute()),
        icon: const Icon(Icons.add),
        label: const Text('QR生成'),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'generate',
          onPressed: () => context.router.push(const GeneratorRoute()),
          tooltip: 'QR生成',
          child: const Icon(Icons.add),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          height: 56,
          child: FilledButton.icon(
            onPressed: () => context.router.push(const ScannerRoute()),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('QRをスキャン'),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'search-bottom',
          onPressed: () => context.router.push(const SearchRoute()),
          tooltip: '検索',
          child: const Icon(Icons.search),
        ),
      ],
    );
  }

  /// リスト表示用のサムネイルを構築する。
  ///
  /// QR未登録エントリはグレースケール表示にし、
  /// decode 負荷を抑えるため cacheWidth を指定する。
  Widget _buildListThumbnail(
    QrEntryModel entry,
    ThemeData theme, {
    required double size,
  }) {
    Widget thumbnail;
    if (entry.thumbnail != null) {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          entry.thumbnail!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          cacheWidth: 160,
          filterQuality: FilterQuality.low,
        ),
      );
    } else {
      thumbnail = Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.qr_code_2),
      );
    }

    final sized = SizedBox(width: size, height: size, child: thumbnail);
    if (entry.hasQrData) {
      return sized;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Opacity(opacity: 0.55, child: sized),
    );
  }

  /// 選択中エントリにカテゴリを一括設定する。
  Future<void> _showCategoryEditorForSelected() async {
    final categories = ref
        .read(allCategoriesProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <CategoryModel>[],
        );
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('カテゴリを設定')),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('未分類にする'),
              onTap: () => Navigator.of(context).pop(null),
            ),
            for (final category in categories)
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(category.name),
                onTap: () => Navigator.of(context).pop(category.id),
              ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    await ref
        .read(qrRepositoryProvider)
        .setCategoryForEntries(_selectedIds.toList(), selected);
    _clearSelection();
    setState(() => _categoryEditMode = false);
  }
}

/// カテゴリ見出しをピン止め表示する Sliver ヘッダー。
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({
    required this.categoryName,
    required this.itemCount,
    required this.expanded,
    required this.onTap,
    required this.backgroundColor,
  });

  final String categoryName;
  final int itemCount;
  final bool expanded;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$categoryName ($itemCount)')),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return categoryName != oldDelegate.categoryName ||
        itemCount != oldDelegate.itemCount ||
        expanded != oldDelegate.expanded ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
