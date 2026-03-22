import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/widgets/tag_chips.dart';

void main() {
  testWidgets('タグが多い場合でも高さ制限内でスクロール表示できる', (tester) async {
    final tags = List<TagModel>.generate(
      20,
      (index) =>
          TagModel(id: 'tag-$index', name: 'タグ$index', color: 0xFF6750A4),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagChips(tags: tags, selectable: true, maxHeight: 100),
        ),
      ),
    );

    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    final scrollableSize = tester.getSize(scrollViewFinder);
    expect(scrollableSize.height, lessThanOrEqualTo(100));
  });
}
