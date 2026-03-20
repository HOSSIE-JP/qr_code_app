// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DetailPage]
class DetailRoute extends PageRouteInfo<DetailRouteArgs> {
  DetailRoute({
    Key? key,
    required String entryId,
    String? scopedEntryIds,
    int? initialIndex,
    List<PageRouteInfo>? children,
  }) : super(
         DetailRoute.name,
         args: DetailRouteArgs(
           key: key,
           entryId: entryId,
           scopedEntryIds: scopedEntryIds,
           initialIndex: initialIndex,
         ),
         initialChildren: children,
       );

  static const String name = 'DetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailRouteArgs>();
      return DetailPage(
        key: args.key,
        entryId: args.entryId,
        scopedEntryIds: args.scopedEntryIds,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class DetailRouteArgs {
  const DetailRouteArgs({
    this.key,
    required this.entryId,
    this.scopedEntryIds,
    this.initialIndex,
  });

  final Key? key;

  final String entryId;

  final String? scopedEntryIds;

  final int? initialIndex;

  @override
  String toString() {
    return 'DetailRouteArgs{key: $key, entryId: $entryId, scopedEntryIds: $scopedEntryIds, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DetailRouteArgs) return false;
    return key == other.key &&
        entryId == other.entryId &&
        scopedEntryIds == other.scopedEntryIds &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      entryId.hashCode ^
      scopedEntryIds.hashCode ^
      initialIndex.hashCode;
}

/// generated route for
/// [EditPage]
class EditRoute extends PageRouteInfo<EditRouteArgs> {
  EditRoute({Key? key, required String entryId, List<PageRouteInfo>? children})
    : super(
        EditRoute.name,
        args: EditRouteArgs(key: key, entryId: entryId),
        initialChildren: children,
      );

  static const String name = 'EditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditRouteArgs>();
      return EditPage(key: args.key, entryId: args.entryId);
    },
  );
}

class EditRouteArgs {
  const EditRouteArgs({this.key, required this.entryId});

  final Key? key;

  final String entryId;

  @override
  String toString() {
    return 'EditRouteArgs{key: $key, entryId: $entryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditRouteArgs) return false;
    return key == other.key && entryId == other.entryId;
  }

  @override
  int get hashCode => key.hashCode ^ entryId.hashCode;
}

/// generated route for
/// [ExportPage]
class ExportRoute extends PageRouteInfo<void> {
  const ExportRoute({List<PageRouteInfo>? children})
    : super(ExportRoute.name, initialChildren: children);

  static const String name = 'ExportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ExportPage();
    },
  );
}

/// generated route for
/// [GeneratorPage]
class GeneratorRoute extends PageRouteInfo<void> {
  const GeneratorRoute({List<PageRouteInfo>? children})
    : super(GeneratorRoute.name, initialChildren: children);

  static const String name = 'GeneratorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const GeneratorPage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [ImportPage]
class ImportRoute extends PageRouteInfo<void> {
  const ImportRoute({List<PageRouteInfo>? children})
    : super(ImportRoute.name, initialChildren: children);

  static const String name = 'ImportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ImportPage();
    },
  );
}

/// generated route for
/// [QrViewerPage]
class QrViewerRoute extends PageRouteInfo<QrViewerRouteArgs> {
  QrViewerRoute({
    Key? key,
    required String entryId,
    List<PageRouteInfo>? children,
  }) : super(
         QrViewerRoute.name,
         args: QrViewerRouteArgs(key: key, entryId: entryId),
         initialChildren: children,
       );

  static const String name = 'QrViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<QrViewerRouteArgs>();
      return QrViewerPage(key: args.key, entryId: args.entryId);
    },
  );
}

class QrViewerRouteArgs {
  const QrViewerRouteArgs({this.key, required this.entryId});

  final Key? key;

  final String entryId;

  @override
  String toString() {
    return 'QrViewerRouteArgs{key: $key, entryId: $entryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QrViewerRouteArgs) return false;
    return key == other.key && entryId == other.entryId;
  }

  @override
  int get hashCode => key.hashCode ^ entryId.hashCode;
}

/// generated route for
/// [ScanProgressPage]
class ScanProgressRoute extends PageRouteInfo<ScanProgressRouteArgs> {
  ScanProgressRoute({
    Key? key,
    required Uint8List scannedData,
    bool isTextMode = false,
    List<PageRouteInfo>? children,
  }) : super(
         ScanProgressRoute.name,
         args: ScanProgressRouteArgs(
           key: key,
           scannedData: scannedData,
           isTextMode: isTextMode,
         ),
         initialChildren: children,
       );

  static const String name = 'ScanProgressRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ScanProgressRouteArgs>();
      return ScanProgressPage(
        key: args.key,
        scannedData: args.scannedData,
        isTextMode: args.isTextMode,
      );
    },
  );
}

class ScanProgressRouteArgs {
  const ScanProgressRouteArgs({
    this.key,
    required this.scannedData,
    this.isTextMode = false,
  });

  final Key? key;

  final Uint8List scannedData;

  final bool isTextMode;

  @override
  String toString() {
    return 'ScanProgressRouteArgs{key: $key, scannedData: $scannedData, isTextMode: $isTextMode}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScanProgressRouteArgs) return false;
    return key == other.key &&
        scannedData == other.scannedData &&
        isTextMode == other.isTextMode;
  }

  @override
  int get hashCode => key.hashCode ^ scannedData.hashCode ^ isTextMode.hashCode;
}

/// generated route for
/// [ScannerPage]
class ScannerRoute extends PageRouteInfo<void> {
  const ScannerRoute({List<PageRouteInfo>? children})
    : super(ScannerRoute.name, initialChildren: children);

  static const String name = 'ScannerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ScannerPage();
    },
  );
}

/// generated route for
/// [SearchPage]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SearchPage();
    },
  );
}

/// generated route for
/// [SettingsPage]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsPage();
    },
  );
}

/// generated route for
/// [ThumbnailCropPage]
class ThumbnailCropRoute extends PageRouteInfo<ThumbnailCropRouteArgs> {
  ThumbnailCropRoute({
    Key? key,
    required Uint8List imageBytes,
    List<PageRouteInfo>? children,
  }) : super(
         ThumbnailCropRoute.name,
         args: ThumbnailCropRouteArgs(key: key, imageBytes: imageBytes),
         initialChildren: children,
       );

  static const String name = 'ThumbnailCropRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ThumbnailCropRouteArgs>();
      return ThumbnailCropPage(key: args.key, imageBytes: args.imageBytes);
    },
  );
}

class ThumbnailCropRouteArgs {
  const ThumbnailCropRouteArgs({this.key, required this.imageBytes});

  final Key? key;

  final Uint8List imageBytes;

  @override
  String toString() {
    return 'ThumbnailCropRouteArgs{key: $key, imageBytes: $imageBytes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ThumbnailCropRouteArgs) return false;
    return key == other.key && imageBytes == other.imageBytes;
  }

  @override
  int get hashCode => key.hashCode ^ imageBytes.hashCode;
}
