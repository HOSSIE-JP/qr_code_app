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

  /// 保存完了時に保存先パスと dirty フラグを更新する。
  void markSaved(String? sourcePath) {
    state = state.copyWith(sourcePath: sourcePath, isDirty: false);
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
