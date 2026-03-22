// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリ全体で共有する drift データベースインスタンス。

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// アプリ全体で共有する drift データベースインスタンス。

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// アプリ全体で共有する drift データベースインスタンス。
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// QR エントリ操作用リポジトリ。

@ProviderFor(qrRepository)
final qrRepositoryProvider = QrRepositoryProvider._();

/// QR エントリ操作用リポジトリ。

final class QrRepositoryProvider
    extends $FunctionalProvider<QrRepository, QrRepository, QrRepository>
    with $Provider<QrRepository> {
  /// QR エントリ操作用リポジトリ。
  QrRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrRepositoryHash();

  @$internal
  @override
  $ProviderElement<QrRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QrRepository create(Ref ref) {
    return qrRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrRepository>(value),
    );
  }
}

String _$qrRepositoryHash() => r'7a506618d7f298bb7fe1687d86c505dcbcf1ffc9';

/// タグ操作用リポジトリ。

@ProviderFor(tagRepository)
final tagRepositoryProvider = TagRepositoryProvider._();

/// タグ操作用リポジトリ。

final class TagRepositoryProvider
    extends $FunctionalProvider<TagRepository, TagRepository, TagRepository>
    with $Provider<TagRepository> {
  /// タグ操作用リポジトリ。
  TagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRepositoryHash();

  @$internal
  @override
  $ProviderElement<TagRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagRepository create(Ref ref) {
    return tagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagRepository>(value),
    );
  }
}

String _$tagRepositoryHash() => r'1a764a09ef13ccaac28cd5a0c4a18d81ee396093';

/// エクスポート・インポート操作用リポジトリ。

@ProviderFor(exportRepository)
final exportRepositoryProvider = ExportRepositoryProvider._();

/// エクスポート・インポート操作用リポジトリ。

final class ExportRepositoryProvider
    extends
        $FunctionalProvider<
          ExportRepository,
          ExportRepository,
          ExportRepository
        >
    with $Provider<ExportRepository> {
  /// エクスポート・インポート操作用リポジトリ。
  ExportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportRepository create(Ref ref) {
    return exportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportRepository>(value),
    );
  }
}

String _$exportRepositoryHash() => r'd18e6c3a35882b40191cb489e725472346302e59';

/// 現在選択中のデータベース ID。

@ProviderFor(CurrentDatabaseId)
final currentDatabaseIdProvider = CurrentDatabaseIdProvider._();

/// 現在選択中のデータベース ID。
final class CurrentDatabaseIdProvider
    extends $NotifierProvider<CurrentDatabaseId, String> {
  /// 現在選択中のデータベース ID。
  CurrentDatabaseIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDatabaseIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDatabaseIdHash();

  @$internal
  @override
  CurrentDatabaseId create() => CurrentDatabaseId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentDatabaseIdHash() => r'd10a918af4290fc35697cfc39dc877b704d83e89';

/// 現在選択中のデータベース ID。

abstract class _$CurrentDatabaseId extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 全データベース一覧を監視する。

@ProviderFor(allDatabases)
final allDatabasesProvider = AllDatabasesProvider._();

/// 全データベース一覧を監視する。

final class AllDatabasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QrDatabaseModel>>,
          List<QrDatabaseModel>,
          Stream<List<QrDatabaseModel>>
        >
    with
        $FutureModifier<List<QrDatabaseModel>>,
        $StreamProvider<List<QrDatabaseModel>> {
  /// 全データベース一覧を監視する。
  AllDatabasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allDatabasesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allDatabasesHash();

  @$internal
  @override
  $StreamProviderElement<List<QrDatabaseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<QrDatabaseModel>> create(Ref ref) {
    return allDatabases(ref);
  }
}

String _$allDatabasesHash() => r'798470a9c4b7f2e5f561e74292719f5b55f50fb9';

/// 現在の DB のカテゴリを表示順で監視する。

@ProviderFor(allCategories)
final allCategoriesProvider = AllCategoriesProvider._();

/// 現在の DB のカテゴリを表示順で監視する。

final class AllCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryModel>>,
          List<CategoryModel>,
          Stream<List<CategoryModel>>
        >
    with
        $FutureModifier<List<CategoryModel>>,
        $StreamProvider<List<CategoryModel>> {
  /// 現在の DB のカテゴリを表示順で監視する。
  AllCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allCategoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<CategoryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryModel>> create(Ref ref) {
    return allCategories(ref);
  }
}

String _$allCategoriesHash() => r'dd4184d37c18e3c068e72da55f191623f2c65306';

/// ソート設定を管理する Notifier。

@ProviderFor(SortConfig)
final sortConfigProvider = SortConfigProvider._();

/// ソート設定を管理する Notifier。
final class SortConfigProvider
    extends $NotifierProvider<SortConfig, ({bool ascending, SortField field})> {
  /// ソート設定を管理する Notifier。
  SortConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortConfigHash();

  @$internal
  @override
  SortConfig create() => SortConfig();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({bool ascending, SortField field}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({bool ascending, SortField field})>(
        value,
      ),
    );
  }
}

String _$sortConfigHash() => r'cda1389a64565b2ef8a0a3392cb6228338c664e3';

/// ソート設定を管理する Notifier。

abstract class _$SortConfig
    extends $Notifier<({bool ascending, SortField field})> {
  ({bool ascending, SortField field}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({bool ascending, SortField field}),
              ({bool ascending, SortField field})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({bool ascending, SortField field}),
                ({bool ascending, SortField field})
              >,
              ({bool ascending, SortField field}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// QR ビューワーの初期表示サイズ設定を保持する Notifier。

@ProviderFor(QrViewerDefaultSize)
final qrViewerDefaultSizeProvider = QrViewerDefaultSizeProvider._();

/// QR ビューワーの初期表示サイズ設定を保持する Notifier。
final class QrViewerDefaultSizeProvider
    extends $NotifierProvider<QrViewerDefaultSize, double> {
  /// QR ビューワーの初期表示サイズ設定を保持する Notifier。
  QrViewerDefaultSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrViewerDefaultSizeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrViewerDefaultSizeHash();

  @$internal
  @override
  QrViewerDefaultSize create() => QrViewerDefaultSize();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$qrViewerDefaultSizeHash() =>
    r'59f3f2220daf11dabe5aceb230c79563e70e0cb1';

/// QR ビューワーの初期表示サイズ設定を保持する Notifier。

abstract class _$QrViewerDefaultSize extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// QR の生成・描画パラメータを保持する Notifier。

@ProviderFor(QrGenerationSettings)
final qrGenerationSettingsProvider = QrGenerationSettingsProvider._();

/// QR の生成・描画パラメータを保持する Notifier。
final class QrGenerationSettingsProvider
    extends $NotifierProvider<QrGenerationSettings, QrGenerationConfig> {
  /// QR の生成・描画パラメータを保持する Notifier。
  QrGenerationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrGenerationSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrGenerationSettingsHash();

  @$internal
  @override
  QrGenerationSettings create() => QrGenerationSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrGenerationConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrGenerationConfig>(value),
    );
  }
}

String _$qrGenerationSettingsHash() =>
    r'a9ab75ed96298adc25994392d96d25963d8dcdf6';

/// QR の生成・描画パラメータを保持する Notifier。

abstract class _$QrGenerationSettings extends $Notifier<QrGenerationConfig> {
  QrGenerationConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QrGenerationConfig, QrGenerationConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QrGenerationConfig, QrGenerationConfig>,
              QrGenerationConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 現在の DB のエントリをリアルタイム監視し、ソート済みで返す。

@ProviderFor(qrEntries)
final qrEntriesProvider = QrEntriesProvider._();

/// 現在の DB のエントリをリアルタイム監視し、ソート済みで返す。

final class QrEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QrEntryModel>>,
          List<QrEntryModel>,
          Stream<List<QrEntryModel>>
        >
    with
        $FutureModifier<List<QrEntryModel>>,
        $StreamProvider<List<QrEntryModel>> {
  /// 現在の DB のエントリをリアルタイム監視し、ソート済みで返す。
  QrEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<QrEntryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<QrEntryModel>> create(Ref ref) {
    return qrEntries(ref);
  }
}

String _$qrEntriesHash() => r'1a797eae7a3dcd365688d56ce69066ebc24171a2';

/// 指定 ID のエントリを取得する。

@ProviderFor(qrEntryById)
final qrEntryByIdProvider = QrEntryByIdFamily._();

/// 指定 ID のエントリを取得する。

final class QrEntryByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<QrEntryModel?>,
          QrEntryModel?,
          FutureOr<QrEntryModel?>
        >
    with $FutureModifier<QrEntryModel?>, $FutureProvider<QrEntryModel?> {
  /// 指定 ID のエントリを取得する。
  QrEntryByIdProvider._({
    required QrEntryByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'qrEntryByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$qrEntryByIdHash();

  @override
  String toString() {
    return r'qrEntryByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<QrEntryModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QrEntryModel?> create(Ref ref) {
    final argument = this.argument as String;
    return qrEntryById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QrEntryByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$qrEntryByIdHash() => r'7d75c40c185fd56886c172d9776b3151ef06dedd';

/// 指定 ID のエントリを取得する。

final class QrEntryByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<QrEntryModel?>, String> {
  QrEntryByIdFamily._()
    : super(
        retry: null,
        name: r'qrEntryByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 指定 ID のエントリを取得する。

  QrEntryByIdProvider call(String id) =>
      QrEntryByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'qrEntryByIdProvider';
}

/// 現在の DB のタグをリアルタイム監視する。

@ProviderFor(allTags)
final allTagsProvider = AllTagsProvider._();

/// 現在の DB のタグをリアルタイム監視する。

final class AllTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TagModel>>,
          List<TagModel>,
          Stream<List<TagModel>>
        >
    with $FutureModifier<List<TagModel>>, $StreamProvider<List<TagModel>> {
  /// 現在の DB のタグをリアルタイム監視する。
  AllTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allTagsHash();

  @$internal
  @override
  $StreamProviderElement<List<TagModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TagModel>> create(Ref ref) {
    return allTags(ref);
  }
}

String _$allTagsHash() => r'2d473b6b42494fad56dd7a4287af8691e71e3ada';

/// 検索状態を管理する Notifier。テキストクエリ、タグフィルタ、QR登録状態を保持する。

@ProviderFor(SearchState)
final searchStateProvider = SearchStateProvider._();

/// 検索状態を管理する Notifier。テキストクエリ、タグフィルタ、QR登録状態を保持する。
final class SearchStateProvider
    extends
        $NotifierProvider<
          SearchState,
          ({bool? hasQrData, List<String> tagIds, String textQuery})
        > {
  /// 検索状態を管理する Notifier。テキストクエリ、タグフィルタ、QR登録状態を保持する。
  SearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchStateHash();

  @$internal
  @override
  SearchState create() => SearchState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({bool? hasQrData, List<String> tagIds, String textQuery}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({bool? hasQrData, List<String> tagIds, String textQuery})
          >(value),
    );
  }
}

String _$searchStateHash() => r'538946fef75dab034cb8f71c34fd581613a19fc5';

/// 検索状態を管理する Notifier。テキストクエリ、タグフィルタ、QR登録状態を保持する。

abstract class _$SearchState
    extends
        $Notifier<({bool? hasQrData, List<String> tagIds, String textQuery})> {
  ({bool? hasQrData, List<String> tagIds, String textQuery}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({bool? hasQrData, List<String> tagIds, String textQuery}),
              ({bool? hasQrData, List<String> tagIds, String textQuery})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({bool? hasQrData, List<String> tagIds, String textQuery}),
                ({bool? hasQrData, List<String> tagIds, String textQuery})
              >,
              ({bool? hasQrData, List<String> tagIds, String textQuery}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QrEntryModel>>,
          List<QrEntryModel>,
          FutureOr<List<QrEntryModel>>
        >
    with
        $FutureModifier<List<QrEntryModel>>,
        $FutureProvider<List<QrEntryModel>> {
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<QrEntryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<QrEntryModel>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'0ae44cec1e0e309051e6d56a6873db76c9daa27c';

/// アプリ内表示用のバージョン文字列を返す。
///
/// 形式は `version+buildNumber`。
/// buildNumber が空の場合は `version` のみ返す。

@ProviderFor(appVersionLabel)
final appVersionLabelProvider = AppVersionLabelProvider._();

/// アプリ内表示用のバージョン文字列を返す。
///
/// 形式は `version+buildNumber`。
/// buildNumber が空の場合は `version` のみ返す。

final class AppVersionLabelProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// アプリ内表示用のバージョン文字列を返す。
  ///
  /// 形式は `version+buildNumber`。
  /// buildNumber が空の場合は `version` のみ返す。
  AppVersionLabelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionLabelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionLabelHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersionLabel(ref);
  }
}

String _$appVersionLabelHash() => r'0d3a30edb7adb9b49db8b02de412d79ee5446b1f';

/// クラウドバックアップ連携サービス。

@ProviderFor(cloudBackupService)
final cloudBackupServiceProvider = CloudBackupServiceProvider._();

/// クラウドバックアップ連携サービス。

final class CloudBackupServiceProvider
    extends
        $FunctionalProvider<
          CloudBackupService,
          CloudBackupService,
          CloudBackupService
        >
    with $Provider<CloudBackupService> {
  /// クラウドバックアップ連携サービス。
  CloudBackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudBackupServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudBackupServiceHash();

  @$internal
  @override
  $ProviderElement<CloudBackupService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloudBackupService create(Ref ref) {
    return cloudBackupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudBackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudBackupService>(value),
    );
  }
}

String _$cloudBackupServiceHash() =>
    r'a5d3c225e192d3bbcd802b6695c7f6f6aa54a2e6';

/// Import 画面で利用するファイル選択サービス。

@ProviderFor(importFilePickerService)
final importFilePickerServiceProvider = ImportFilePickerServiceProvider._();

/// Import 画面で利用するファイル選択サービス。

final class ImportFilePickerServiceProvider
    extends
        $FunctionalProvider<
          ImportFilePickerService,
          ImportFilePickerService,
          ImportFilePickerService
        >
    with $Provider<ImportFilePickerService> {
  /// Import 画面で利用するファイル選択サービス。
  ImportFilePickerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importFilePickerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importFilePickerServiceHash();

  @$internal
  @override
  $ProviderElement<ImportFilePickerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportFilePickerService create(Ref ref) {
    return importFilePickerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportFilePickerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportFilePickerService>(value),
    );
  }
}

String _$importFilePickerServiceHash() =>
    r'a1ed7e2616843fb45e66d54ba6337ed11d032147';
