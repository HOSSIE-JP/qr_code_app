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

  @override
  void initState() {
    super.initState();
    // Sync text controller with search state
    final currentText = ref.read(searchStateProvider).textQuery;
    _searchController.text = currentText;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                return _buildResults(entries);
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
        return GridView.builder(
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
}
