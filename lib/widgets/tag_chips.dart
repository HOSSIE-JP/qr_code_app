import 'package:flutter/material.dart';

import '../data/models/qr_entry_model.dart';

/// タグを Chip / FilterChip として表示する汎用ウィジェット。
///
/// [selectable] が true の場合は FilterChip で選択／解除が可能。
/// false の場合は読み取り専用の Chip として表示される。
class TagChips extends StatelessWidget {
  const TagChips({
    super.key,
    required this.tags,
    this.selectedTagIds = const [],
    this.onTagToggled,
    this.selectable = false,
    this.maxHeight,
  });

  final List<TagModel> tags;
  final List<String> selectedTagIds;
  final ValueChanged<String>? onTagToggled;
  final bool selectable;
  final double? maxHeight;

  /// タグ一覧を高さ制限付きで描画し、必要時は内部スクロールへ切り替える。
  ///
  /// タグ件数が多い場合でも、周辺の操作 UI を押し出さないことを目的とする。
  Widget _buildScrollableChipArea(BuildContext context) {
    final chips = Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        final isSelected = selectedTagIds.contains(tag.id);
        if (selectable) {
          return FilterChip(
            label: Text(tag.name),
            selected: isSelected,
            onSelected: (_) => onTagToggled?.call(tag.id),
            backgroundColor: Color(tag.color).withValues(alpha: 0.1),
            selectedColor: Color(tag.color).withValues(alpha: 0.3),
            checkmarkColor: Color(tag.color),
            side: BorderSide(
              color: isSelected
                  ? Color(tag.color)
                  : Color(tag.color).withValues(alpha: 0.3),
            ),
          );
        }
        return Chip(
          label: Text(
            tag.name,
            style: TextStyle(color: Color(tag.color), fontSize: 12),
          ),
          backgroundColor: Color(tag.color).withValues(alpha: 0.1),
          side: BorderSide(color: Color(tag.color).withValues(alpha: 0.3)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );

    final effectiveMaxHeight = maxHeight;
    if (effectiveMaxHeight == null) {
      return chips;
    }

    return Scrollbar(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 4),
          child: chips,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildScrollableChipArea(context);
  }
}
