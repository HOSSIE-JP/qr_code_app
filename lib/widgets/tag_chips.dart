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
  });

  final List<TagModel> tags;
  final List<String> selectedTagIds;
  final ValueChanged<String>? onTagToggled;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
  }
}
