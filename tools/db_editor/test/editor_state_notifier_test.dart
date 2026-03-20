import 'package:db_editor/src/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorStateNotifier', () {
    test('新規エントリを追加すると選択状態が更新される', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorStateProvider.notifier).addEntry();
      final document = container.read(editorStateProvider);

      expect(document.entries, hasLength(1));
      expect(document.selectedEntryId, document.entries.first.id);
      expect(document.isDirty, isTrue);
    });

    test('タグの追加とエントリへの割当ができる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorStateProvider.notifier);

      notifier.addEntry();
      notifier.addTag('仕事');
      final tagId = container.read(editorStateProvider).tags.single.id;

      notifier.toggleTagForSelectedEntry(tagId);

      final entry = container.read(editorStateProvider).entries.single;
      expect(entry.tags.map((tag) => tag.name), contains('仕事'));
    });

    test('既存エントリを削除できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorStateProvider.notifier);

      notifier.addEntry();
      final entryId = container.read(editorStateProvider).entries.single.id;

      notifier.deleteEntry(entryId);

      final document = container.read(editorStateProvider);
      expect(document.entries, isEmpty);
      expect(document.selectedEntryId, isNull);
    });

    test('カテゴリの追加と削除ができ、削除時は未分類になる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorStateProvider.notifier);

      notifier.addEntry();
      notifier.addCategory('業務');
      final categoryId = container
          .read(editorStateProvider)
          .categories
          .single
          .id;

      notifier.updateSelectedEntry(categoryId: categoryId);
      notifier.deleteCategory(categoryId);

      final document = container.read(editorStateProvider);
      expect(document.categories, isEmpty);
      expect(document.entries.single.categoryId, isNull);
    });
  });
}
