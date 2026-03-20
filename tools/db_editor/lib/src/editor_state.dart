import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_shared/qr_shared.dart';

/// エディタ全体で扱うドキュメント状態。
@immutable
class EditorDocument {
  const EditorDocument({
    required this.entries,
    required this.tags,
    required this.categories,
    required this.version,
    required this.exportedAt,
    this.sourcePath,
    this.selectedEntryId,
    this.filterText = '',
    this.sortField = EntrySortField.updatedAt,
    this.ascending = false,
    this.isDirty = false,
  });

  final List<QrEntryModel> entries;
  final List<TagModel> tags;
  final List<CategoryModel> categories;
  final int version;
  final DateTime exportedAt;
  final String? sourcePath;
  final String? selectedEntryId;
  final String filterText;
  final EntrySortField sortField;
  final bool ascending;
  final bool isDirty;

  EditorDocument copyWith({
    List<QrEntryModel>? entries,
    List<TagModel>? tags,
    List<CategoryModel>? categories,
    int? version,
    DateTime? exportedAt,
    String? sourcePath,
    String? selectedEntryId,
    String? filterText,
    EntrySortField? sortField,
    bool? ascending,
    bool? isDirty,
  }) {
    return EditorDocument(
      entries: entries ?? this.entries,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      version: version ?? this.version,
      exportedAt: exportedAt ?? this.exportedAt,
      sourcePath: sourcePath ?? this.sourcePath,
      selectedEntryId: selectedEntryId ?? this.selectedEntryId,
      filterText: filterText ?? this.filterText,
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  static EditorDocument empty() => EditorDocument(
    entries: const <QrEntryModel>[],
    tags: const <TagModel>[],
    categories: const <CategoryModel>[],
    version: 1,
    exportedAt: DateTime.now().toUtc(),
  );
}

enum EntrySortField { name, createdAt, updatedAt, dataSize }

/// .qrjson/.json の編集状態を管理する Notifier。
class EditorStateNotifier extends Notifier<EditorDocument> {
  @override
  EditorDocument build() {
    return EditorDocument.empty();
  }

  QrEntryModel? get selectedEntry {
    final selectedId = state.selectedEntryId;
    if (selectedId == null) {
      return null;
    }
    for (final entry in state.entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  List<QrEntryModel> get visibleEntries {
    final filter = state.filterText.trim().toLowerCase();
    final filtered = state.entries.where((entry) {
      if (filter.isEmpty) {
        return true;
      }
      return entry.name.toLowerCase().contains(filter) ||
          entry.description.toLowerCase().contains(filter) ||
          entry.id.toLowerCase().contains(filter);
    }).toList();

    int compare(QrEntryModel left, QrEntryModel right) {
      switch (state.sortField) {
        case EntrySortField.name:
          return left.name.compareTo(right.name);
        case EntrySortField.createdAt:
          return left.createdAt.compareTo(right.createdAt);
        case EntrySortField.updatedAt:
          return left.updatedAt.compareTo(right.updatedAt);
        case EntrySortField.dataSize:
          return left.dataSize.compareTo(right.dataSize);
      }
    }

    filtered.sort((left, right) {
      final result = compare(left, right);
      return state.ascending ? result : -result;
    });
    return filtered;
  }

  void loadFromJsonString(String content, {String? sourcePath}) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('トップレベルがMap形式ではありません。');
    }

    final rawEntries = decoded['entries'];
    if (rawEntries is! List<dynamic>) {
      throw const FormatException('entries が配列ではありません。');
    }

    final rawTags = decoded['tags'];
    final rawCategories = decoded['categories'];

    final tags = (rawTags is List<dynamic> ? rawTags : const <dynamic>[])
        .map((json) => TagModel.fromJson(_asMap(json)))
        .toList();
    final categories =
        (rawCategories is List<dynamic> ? rawCategories : const <dynamic>[])
            .map((json) => CategoryModel.fromJson(_asMap(json)))
            .toList();
    final entries = rawEntries
        .map((json) => QrEntryModel.fromJson(_asMap(json)))
        .toList();

    final versionValue = decoded['version'];
    final version = versionValue is int ? versionValue : 1;
    final exportedAtValue = decoded['exportedAt'];
    final exportedAt = exportedAtValue is String
        ? DateTime.tryParse(exportedAtValue)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    state = EditorDocument(
      entries: entries,
      tags: tags,
      categories: categories,
      version: version,
      exportedAt: exportedAt,
      sourcePath: sourcePath,
      selectedEntryId: entries.isEmpty ? null : entries.first.id,
    );
  }

  /// 外部サービスで読み込んだドキュメントを現在状態として適用する。
  void replaceDocument(EditorDocument document) {
    state = document;
  }

  String toJsonString() {
    final jsonMap = <String, dynamic>{
      'version': state.version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tags': state.tags.map((tag) => tag.toJson()).toList(),
      'categories': state.categories
          .map((category) => category.toJson())
          .toList(),
      'entries': state.entries.map((entry) => entry.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(jsonMap);
  }

  void selectEntry(String entryId) {
    state = state.copyWith(selectedEntryId: entryId);
  }

  void updateFilter(String filterText) {
    state = state.copyWith(filterText: filterText);
  }

  void updateSort(EntrySortField field) {
    final ascending = state.sortField == field ? !state.ascending : true;
    state = state.copyWith(sortField: field, ascending: ascending);
  }

  void updateSelectedEntry({
    String? name,
    String? description,
    bool? isTextMode,
    bool? isFavorite,
    String? categoryId,
  }) {
    final selectedId = state.selectedEntryId;
    if (selectedId == null) {
      return;
    }

    final updatedEntries = state.entries.map((entry) {
      if (entry.id != selectedId) {
        return entry;
      }
      return entry.copyWith(
        name: name ?? entry.name,
        description: description ?? entry.description,
        isTextMode: isTextMode ?? entry.isTextMode,
        isFavorite: isFavorite ?? entry.isFavorite,
        categoryId: categoryId,
        updatedAt: DateTime.now(),
      );
    }).toList();

    state = state.copyWith(entries: updatedEntries, isDirty: true);
  }

  /// 指定エントリのお気に入り状態を更新する。
  void setEntryFavorite(String entryId, bool isFavorite) {
    _updateEntryById(
      entryId,
      (entry) =>
          entry.copyWith(isFavorite: isFavorite, updatedAt: DateTime.now()),
    );
  }

  /// 指定エントリのテキストモード状態を更新する。
  void setEntryTextMode(String entryId, bool isTextMode) {
    _updateEntryById(
      entryId,
      (entry) =>
          entry.copyWith(isTextMode: isTextMode, updatedAt: DateTime.now()),
    );
  }

  void setSelectedThumbnail(Uint8List? thumbnailBytes) {
    final selectedId = state.selectedEntryId;
    if (selectedId == null) {
      return;
    }

    final updatedEntries = state.entries.map((entry) {
      if (entry.id != selectedId) {
        return entry;
      }
      return entry.copyWith(
        thumbnail: thumbnailBytes,
        updatedAt: DateTime.now(),
      );
    }).toList();

    state = state.copyWith(entries: updatedEntries, isDirty: true);
  }

  /// 新規エントリを追加し、選択状態をそのエントリに切り替える。
  void addEntry() {
    final now = DateTime.now();
    final id = 'entry_${now.microsecondsSinceEpoch.toRadixString(36)}';
    final databaseId = state.entries.isNotEmpty
        ? state.entries.first.databaseId
        : 'default';

    final newEntry = QrEntryModel(
      id: id,
      databaseId: databaseId,
      name: '新規エントリ',
      description: '',
      originalData: Uint8List(0),
      dataSize: 0,
      chunkCount: 0,
      isTextMode: true,
      isFavorite: false,
      thumbnail: null,
      createdAt: now,
      updatedAt: now,
      tags: const <TagModel>[],
    );

    final updatedEntries = <QrEntryModel>[newEntry, ...state.entries];
    state = state.copyWith(
      entries: updatedEntries,
      selectedEntryId: newEntry.id,
      isDirty: true,
    );
  }

  /// 指定エントリを削除する。
  void deleteEntry(String entryId) {
    final beforeCount = state.entries.length;
    final updatedEntries = state.entries
        .where((entry) => entry.id != entryId)
        .toList();
    if (updatedEntries.length == beforeCount) {
      return;
    }

    final nextSelectedId = state.selectedEntryId == entryId
        ? (updatedEntries.isNotEmpty ? updatedEntries.first.id : null)
        : state.selectedEntryId;

    state = EditorDocument(
      entries: updatedEntries,
      tags: state.tags,
      categories: state.categories,
      version: state.version,
      exportedAt: state.exportedAt,
      sourcePath: state.sourcePath,
      selectedEntryId: nextSelectedId,
      filterText: state.filterText,
      sortField: state.sortField,
      ascending: state.ascending,
      isDirty: true,
    );
  }

  /// タグを新規追加する。
  void addTag(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.tags.any((tag) => tag.name == trimmed)) return;

    final now = DateTime.now();
    final id = 'tag_${now.microsecondsSinceEpoch.toRadixString(36)}';
    final databaseId = state.entries.isNotEmpty
        ? state.entries.first.databaseId
        : 'default';
    final tag = TagModel(
      id: id,
      databaseId: databaseId,
      name: trimmed,
      color: 0xFF6750A4,
    );
    state = state.copyWith(tags: [...state.tags, tag], isDirty: true);
  }

  /// タグ名を更新する。
  void renameTag(String tagId, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updatedTags = state.tags
        .map((tag) => tag.id == tagId ? tag.copyWith(name: trimmed) : tag)
        .toList();

    final updatedEntries = state.entries.map((entry) {
      final nextTags = entry.tags
          .map((tag) => tag.id == tagId ? tag.copyWith(name: trimmed) : tag)
          .toList();
      return entry.copyWith(tags: nextTags, updatedAt: DateTime.now());
    }).toList();

    state = state.copyWith(
      tags: updatedTags,
      entries: updatedEntries,
      isDirty: true,
    );
  }

  /// タグを削除し、各エントリからも紐付きを外す。
  void deleteTag(String tagId) {
    final updatedTags = state.tags.where((tag) => tag.id != tagId).toList();
    final updatedEntries = state.entries.map((entry) {
      final nextTags = entry.tags.where((tag) => tag.id != tagId).toList();
      return entry.copyWith(tags: nextTags, updatedAt: DateTime.now());
    }).toList();

    state = state.copyWith(
      tags: updatedTags,
      entries: updatedEntries,
      isDirty: true,
    );
  }

  /// カテゴリを新規追加する。
  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.categories.any((category) => category.name == trimmed)) return;

    final now = DateTime.now();
    final id = 'category_${now.microsecondsSinceEpoch.toRadixString(36)}';
    final databaseId = state.entries.isNotEmpty
        ? state.entries.first.databaseId
        : 'default';
    final category = CategoryModel(
      id: id,
      databaseId: databaseId,
      name: trimmed,
      sortOrder: state.categories.length,
    );
    state = state.copyWith(
      categories: [...state.categories, category],
      isDirty: true,
    );
  }

  /// カテゴリ名を更新する。
  void renameCategory(String categoryId, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updatedCategories = state.categories
        .map(
          (category) => category.id == categoryId
              ? category.copyWith(name: trimmed)
              : category,
        )
        .toList();
    state = state.copyWith(categories: updatedCategories, isDirty: true);
  }

  /// カテゴリを削除し、紐付いているエントリは未分類に戻す。
  void deleteCategory(String categoryId) {
    final updatedCategories = state.categories
        .where((category) => category.id != categoryId)
        .toList();
    final updatedEntries = state.entries
        .map(
          (entry) => entry.categoryId == categoryId
              ? entry.copyWith(categoryId: null, updatedAt: DateTime.now())
              : entry,
        )
        .toList();

    state = state.copyWith(
      categories: updatedCategories,
      entries: updatedEntries,
      isDirty: true,
    );
  }

  /// 選択中エントリに対してタグを付け外しする。
  void toggleTagForSelectedEntry(String tagId) {
    final selectedId = state.selectedEntryId;
    if (selectedId == null) return;

    TagModel? targetTag;
    for (final tag in state.tags) {
      if (tag.id == tagId) {
        targetTag = tag;
        break;
      }
    }
    if (targetTag == null) return;
    final resolvedTag = targetTag;

    final updatedEntries = state.entries.map((entry) {
      if (entry.id != selectedId) return entry;

      final hasTag = entry.tags.any((tag) => tag.id == tagId);
      final nextTags = hasTag
          ? entry.tags.where((tag) => tag.id != tagId).toList()
          : [...entry.tags, resolvedTag];
      return entry.copyWith(tags: nextTags, updatedAt: DateTime.now());
    }).toList();

    state = state.copyWith(entries: updatedEntries, isDirty: true);
  }

  /// 保存完了時に保存先パスと dirty フラグを更新する。
  void markSaved(String? sourcePath) {
    state = state.copyWith(sourcePath: sourcePath, isDirty: false);
  }

  void _updateEntryById(
    String entryId,
    QrEntryModel Function(QrEntryModel entry) transform,
  ) {
    var updated = false;
    final updatedEntries = state.entries.map((entry) {
      if (entry.id != entryId) {
        return entry;
      }
      updated = true;
      return transform(entry);
    }).toList();

    if (!updated) {
      return;
    }
    state = state.copyWith(entries: updatedEntries, isDirty: true);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    throw const FormatException('JSON 要素がMap形式ではありません。');
  }
}
