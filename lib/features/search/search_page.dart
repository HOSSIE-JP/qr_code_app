import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/qr_entry_model.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../widgets/qr_entry_card.dart';
import '../../widgets/tag_chips.dart';

/// エントリの検索ページ。
///
/// AppBar のテキストフィールドで名称・説明・タグ名を検索し、
/// タグの FilterChip でフィルタリング、QR 登録状態で絞り込みができる。
@RoutePage()
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();

  final Map<String, QrEntryModel> _hydratedEntries = <String, QrEntryModel>{};
  final Set<String> _hydratingEntryIds = <String>{};
  List<QrEntryModel> _latestSearchEntries = const <QrEntryModel>[];

  Timer? _hydrateDebounceTimer;
  int _lastGridCrossAxisCount = 2;
  double _lastGridWidth = 0;
  double _lastScrollOffset = 0;
  DateTime? _lastScrollTime;

  /// 可視範囲の詳細読込で、1サイクルあたりに処理する最大件数。
  /// スクロール速度に応じて動的に増減する。
  int _hydrateBatchSize = 8;

  static const double _gridPadding = 16;
  static const double _gridMainAxisSpacing = 12;
  static const double _gridCrossAxisSpacing = 12;
  static const double _gridChildAspectRatio = 0.7;
  static const int _prefetchRows = 2;

  @override
  void initState() {
    super.initState();
    // Sync text controller with search state
    final currentText = ref.read(searchStateProvider).textQuery;
    _searchController.text = currentText;
    _gridScrollController.addListener(_onGridScrolled);
  }

  @override
  void dispose() {
    _gridScrollController.removeListener(_onGridScrolled);
    _gridScrollController.dispose();
    _hydrateDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// グリッドスクロール時に速度を算出し、詳細読込のバッチサイズを更新する。
  void _onGridScrolled() {
    final now = DateTime.now();
    if (_gridScrollController.hasClients) {
      final currentOffset = _gridScrollController.offset;
      final lastTime = _lastScrollTime;
      if (lastTime != null) {
        final elapsedMs = now.difference(lastTime).inMilliseconds;
        if (elapsedMs > 0) {
          final speedPxPerMs =
              (currentOffset - _lastScrollOffset).abs() / elapsedMs;
          _hydrateBatchSize = _resolveHydrateBatchSize(speedPxPerMs);
        }
      }
      _lastScrollOffset = currentOffset;
    }
    _lastScrollTime = now;
    _scheduleHydrateVisibleRange();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchState = ref.watch(searchStateProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final allTagsAsync = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '名称、説明、タグ名で検索...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchStateProvider.notifier).setTextQuery('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(searchStateProvider.notifier).setTextQuery(value);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag filter
          allTagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'タグで絞り込み',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TagChips(
                      tags: tags,
                      selectedTagIds: searchState.tagIds,
                      selectable: true,
                      maxHeight: 120,
                      onTagToggled: (tagId) {
                        ref.read(searchStateProvider.notifier).toggleTag(tagId);
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, e) => const SizedBox.shrink(),
          ),

          // QR 登録状態フィルタ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'QR 状態',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('すべて'),
                  selected: searchState.hasQrData == null,
                  onSelected: (_) {
                    ref.read(searchStateProvider.notifier).setHasQrData(null);
                  },
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('QR 登録済'),
                  selected: searchState.hasQrData == true,
                  onSelected: (_) {
                    ref.read(searchStateProvider.notifier).setHasQrData(true);
                  },
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('QR 未登録'),
                  selected: searchState.hasQrData == false,
                  onSelected: (_) {
                    ref.read(searchStateProvider.notifier).setHasQrData(false);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: resultsAsync.when(
              data: (entries) {
                _onSearchEntriesUpdated(entries);
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text('検索結果がありません', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }
                final displayEntries = entries
                    .map((entry) => _hydratedEntries[entry.id] ?? entry)
                    .toList(growable: false);
                return _buildResults(displayEntries);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('検索エラー: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<QrEntryModel> entries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 3
            : 2;

        _lastGridCrossAxisCount = crossAxisCount;
        _lastGridWidth = constraints.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleHydrateVisibleRange();
        });

        return GridView.builder(
          controller: _gridScrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return QrEntryCard(
              entry: entry,
              onTap: () => context.router.push(
                DetailRoute(
                  entryId: entry.id,
                  scopedEntryIds: entries.map((item) => item.id).join('\n'),
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 検索結果の更新を検知し、詳細読込キャッシュの整合性を維持する。
  void _onSearchEntriesUpdated(List<QrEntryModel> entries) {
    final previousIds = _latestSearchEntries.map((entry) => entry.id).toSet();
    final nextIds = entries.map((entry) => entry.id).toSet();
    if (previousIds.length == nextIds.length &&
        previousIds.containsAll(nextIds)) {
      _latestSearchEntries = entries;
      return;
    }

    _latestSearchEntries = entries;
    _hydratedEntries.removeWhere((entryId, _) => !nextIds.contains(entryId));
    _hydratingEntryIds.removeWhere((entryId) => !nextIds.contains(entryId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleHydrateVisibleRange();
    });
  }

  /// 可視範囲の前後を含めたエントリ詳細読込をスケジュールする。
  void _scheduleHydrateVisibleRange() {
    if (_latestSearchEntries.isEmpty) {
      return;
    }
    _hydrateDebounceTimer?.cancel();
    _hydrateDebounceTimer = Timer(
      const Duration(milliseconds: 80),
      _hydrateVisibleRange,
    );
  }

  /// スクロール速度に応じた詳細読込バッチサイズを返す。
  ///
  /// 高速スクロール時はUI負荷を下げるため小さいバッチ、
  /// 低速スクロール時は表示追従を高めるため大きいバッチを使う。
  int _resolveHydrateBatchSize(double speedPxPerMs) {
    if (speedPxPerMs >= 3.5) return 3;
    if (speedPxPerMs >= 2.0) return 4;
    if (speedPxPerMs >= 1.0) return 6;
    if (speedPxPerMs >= 0.5) return 8;
    return 12;
  }

  /// 可視範囲のエントリを軽量モデルから詳細モデルへ段階的に置き換える。
  Future<void> _hydrateVisibleRange() async {
    if (!mounted || _latestSearchEntries.isEmpty) {
      return;
    }

    int startIndex = 0;
    int endIndex = (_lastGridCrossAxisCount * 2) - 1;

    if (_gridScrollController.hasClients && _lastGridWidth > 0) {
      final position = _gridScrollController.position;
      final gridWidth =
          _lastGridWidth -
          (_gridPadding * 2) -
          (_gridCrossAxisSpacing * (_lastGridCrossAxisCount - 1));
      final itemWidth = gridWidth / _lastGridCrossAxisCount;
      final rowExtent =
          (itemWidth / _gridChildAspectRatio) + _gridMainAxisSpacing;
      final firstVisibleRow = (position.pixels / rowExtent).floor();
      final visibleRowCount =
          (position.viewportDimension / rowExtent).ceil() + _prefetchRows;
      final lastVisibleRow = firstVisibleRow + visibleRowCount;

      startIndex = (firstVisibleRow * _lastGridCrossAxisCount).clamp(
        0,
        _latestSearchEntries.length - 1,
      );
      endIndex = ((lastVisibleRow + 1) * _lastGridCrossAxisCount - 1).clamp(
        0,
        _latestSearchEntries.length - 1,
      );
    } else {
      endIndex = endIndex.clamp(0, _latestSearchEntries.length - 1);
    }

    final repository = ref.read(qrRepositoryProvider);
    var processedCount = 0;
    var hasPendingTarget = false;
    for (var index = startIndex; index <= endIndex; index++) {
      final entryId = _latestSearchEntries[index].id;
      if (_hydratedEntries.containsKey(entryId) ||
          _hydratingEntryIds.contains(entryId)) {
        continue;
      }
      hasPendingTarget = true;
      if (processedCount >= _hydrateBatchSize) {
        break;
      }

      _hydratingEntryIds.add(entryId);
      processedCount++;
      unawaited(
        repository
            .getEntryById(entryId)
            .then((detailedEntry) {
              if (!mounted || detailedEntry == null) {
                return;
              }
              if (_latestSearchEntries.every((entry) => entry.id != entryId)) {
                return;
              }
              setState(() {
                _hydratedEntries[entryId] = detailedEntry;
              });
            })
            .whenComplete(() {
              _hydratingEntryIds.remove(entryId);
            }),
      );
    }

    if (hasPendingTarget && processedCount >= _hydrateBatchSize) {
      _hydrateDebounceTimer?.cancel();
      _hydrateDebounceTimer = Timer(
        const Duration(milliseconds: 16),
        _hydrateVisibleRange,
      );
    }
  }
}
