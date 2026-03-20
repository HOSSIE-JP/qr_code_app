import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/storage/app_prefs.dart';
import '../data/database/app_database.dart';
import '../data/repositories/export_repository.dart';
import '../data/repositories/qr_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../data/models/qr_entry_model.dart';

part 'providers.g.dart';

// --- データベース ---

/// アプリ全体で共有する drift データベースインスタンス。
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

// --- リポジトリ ---

/// QR エントリ操作用リポジトリ。
@riverpod
QrRepository qrRepository(Ref ref) {
  return QrRepository(ref.watch(appDatabaseProvider));
}

/// タグ操作用リポジトリ。
@riverpod
TagRepository tagRepository(Ref ref) {
  return TagRepository(ref.watch(appDatabaseProvider));
}

/// エクスポート・インポート操作用リポジトリ。
@riverpod
ExportRepository exportRepository(Ref ref) {
  return ExportRepository(
    ref.watch(qrRepositoryProvider),
    ref.watch(tagRepositoryProvider),
  );
}

// --- 現在のデータベース ---

/// 現在選択中のデータベース ID。
@Riverpod(keepAlive: true)
class CurrentDatabaseId extends _$CurrentDatabaseId {
  @override
  String build() {
    if (!AppPrefs.isInitialized) {
      return AppDatabase.defaultDatabaseId;
    }
    return AppPrefs.currentDatabaseId ?? AppDatabase.defaultDatabaseId;
  }

  void select(String id) {
    state = id;
    if (AppPrefs.isInitialized) {
      AppPrefs.setCurrentDatabaseId(id);
    }
  }
}

/// 全データベース一覧を監視する。
@riverpod
Stream<List<QrDatabaseModel>> allDatabases(Ref ref) {
  return ref.watch(qrRepositoryProvider).watchAllDatabases();
}

/// 現在の DB のカテゴリを表示順で監視する。
@riverpod
Stream<List<CategoryModel>> allCategories(Ref ref) {
  final dbId = ref.watch(currentDatabaseIdProvider);
  return ref.watch(qrRepositoryProvider).watchCategoriesByDatabase(dbId);
}

// --- ソート ---

/// ソートフィールドの列挙。
enum SortField { name, createdAt, updatedAt }

/// QR 描画時のエラー訂正レベル。
enum QrGenerationErrorLevel { low, medium, quartile, high }

/// QR 描画設定。
class QrGenerationConfig {
  const QrGenerationConfig({
    required this.errorLevel,
    required this.gapless,
    required this.padding,
  });

  final QrGenerationErrorLevel errorLevel;
  final bool gapless;
  final double padding;

  QrGenerationConfig copyWith({
    QrGenerationErrorLevel? errorLevel,
    bool? gapless,
    double? padding,
  }) {
    return QrGenerationConfig(
      errorLevel: errorLevel ?? this.errorLevel,
      gapless: gapless ?? this.gapless,
      padding: padding ?? this.padding,
    );
  }
}

/// ソート設定を管理する Notifier。
@riverpod
class SortConfig extends _$SortConfig {
  @override
  ({SortField field, bool ascending}) build() {
    if (!AppPrefs.isInitialized) {
      return (field: SortField.updatedAt, ascending: false);
    }
    final savedField = AppPrefs.sortField;
    final field = SortField.values.firstWhere(
      (value) => value.name == savedField,
      orElse: () => SortField.updatedAt,
    );
    return (field: field, ascending: AppPrefs.sortAscending ?? false);
  }

  void setField(SortField field) {
    if (state.field == field) {
      // 同じフィールドなら昇降順トグル
      state = (field: field, ascending: !state.ascending);
    } else {
      state = (field: field, ascending: true);
    }
    if (AppPrefs.isInitialized) {
      AppPrefs.setSortField(state.field.name);
      AppPrefs.setSortAscending(state.ascending);
    }
  }
}

/// QR ビューワーの初期表示サイズ設定を保持する Notifier。
@Riverpod(keepAlive: true)
class QrViewerDefaultSize extends _$QrViewerDefaultSize {
  @override
  double build() {
    if (!AppPrefs.isInitialized) return 300;
    return AppPrefs.qrViewerDefaultSize;
  }

  void setSize(double size) {
    state = size;
    if (AppPrefs.isInitialized) {
      AppPrefs.setQrViewerDefaultSize(size);
    }
  }
}

/// QR の生成・描画パラメータを保持する Notifier。
@Riverpod(keepAlive: true)
class QrGenerationSettings extends _$QrGenerationSettings {
  @override
  QrGenerationConfig build() {
    if (!AppPrefs.isInitialized) {
      return const QrGenerationConfig(
        errorLevel: QrGenerationErrorLevel.medium,
        gapless: false,
        padding: 16,
      );
    }

    final level = QrGenerationErrorLevel.values.firstWhere(
      (value) => value.name == AppPrefs.qrGenerationErrorLevel,
      orElse: () => QrGenerationErrorLevel.medium,
    );

    return QrGenerationConfig(
      errorLevel: level,
      gapless: AppPrefs.qrGenerationGapless,
      padding: AppPrefs.qrGenerationPadding,
    );
  }

  void setErrorLevel(QrGenerationErrorLevel value) {
    state = state.copyWith(errorLevel: value);
    if (AppPrefs.isInitialized) {
      AppPrefs.setQrGenerationErrorLevel(value.name);
    }
  }

  void setGapless(bool value) {
    state = state.copyWith(gapless: value);
    if (AppPrefs.isInitialized) {
      AppPrefs.setQrGenerationGapless(value);
    }
  }

  void setPadding(double value) {
    state = state.copyWith(padding: value);
    if (AppPrefs.isInitialized) {
      AppPrefs.setQrGenerationPadding(value);
    }
  }
}

// --- QR エントリ ---

/// 現在の DB のエントリをリアルタイム監視し、ソート済みで返す。
@riverpod
Stream<List<QrEntryModel>> qrEntries(Ref ref) {
  final dbId = ref.watch(currentDatabaseIdProvider);
  final sortConfig = ref.watch(sortConfigProvider);
  return ref.watch(qrRepositoryProvider).watchEntriesByDatabase(dbId).map((
    entries,
  ) {
    final sorted = List<QrEntryModel>.from(entries);
    sorted.sort((a, b) {
      int cmp;
      switch (sortConfig.field) {
        case SortField.name:
          cmp = a.name.compareTo(b.name);
        case SortField.createdAt:
          cmp = a.createdAt.compareTo(b.createdAt);
        case SortField.updatedAt:
          cmp = a.updatedAt.compareTo(b.updatedAt);
      }
      return sortConfig.ascending ? cmp : -cmp;
    });
    return sorted;
  });
}

/// 指定 ID のエントリを取得する。
@riverpod
Future<QrEntryModel?> qrEntryById(Ref ref, String id) {
  return ref.watch(qrRepositoryProvider).getEntryById(id);
}

// --- タグ ---

/// 現在の DB のタグをリアルタイム監視する。
@riverpod
Stream<List<TagModel>> allTags(Ref ref) {
  final dbId = ref.watch(currentDatabaseIdProvider);
  return ref.watch(tagRepositoryProvider).watchTagsByDatabase(dbId);
}

// --- 検索 ---

/// 検索状態を管理する Notifier。テキストクエリ、タグフィルタ、QR登録状態を保持する。
@riverpod
class SearchState extends _$SearchState {
  @override
  ({String textQuery, List<String> tagIds, bool? hasQrData}) build() {
    return (textQuery: '', tagIds: <String>[], hasQrData: null);
  }

  void setTextQuery(String query) {
    state = (
      textQuery: query,
      tagIds: state.tagIds,
      hasQrData: state.hasQrData,
    );
  }

  void setTagIds(List<String> tagIds) {
    state = (
      textQuery: state.textQuery,
      tagIds: tagIds,
      hasQrData: state.hasQrData,
    );
  }

  void toggleTag(String tagId) {
    final current = List<String>.from(state.tagIds);
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      current.add(tagId);
    }
    state = (
      textQuery: state.textQuery,
      tagIds: current,
      hasQrData: state.hasQrData,
    );
  }

  /// QR 登録状態フィルタ。null=すべて, true=登録済, false=未登録。
  void setHasQrData(bool? value) {
    state = (
      textQuery: state.textQuery,
      tagIds: state.tagIds,
      hasQrData: value,
    );
  }

  void clear() {
    state = (textQuery: '', tagIds: <String>[], hasQrData: null);
  }
}

@riverpod
Future<List<QrEntryModel>> searchResults(Ref ref) {
  final searchState = ref.watch(searchStateProvider);
  final dbId = ref.watch(currentDatabaseIdProvider);
  return ref
      .watch(qrRepositoryProvider)
      .search(
        textQuery: searchState.textQuery.isEmpty ? null : searchState.textQuery,
        tagIds: searchState.tagIds,
        databaseId: dbId,
        hasQrData: searchState.hasQrData,
      );
}
