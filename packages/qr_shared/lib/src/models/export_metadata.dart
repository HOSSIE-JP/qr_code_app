import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_metadata.freezed.dart';
part 'export_metadata.g.dart';

/// エクスポートのメタデータを表現する不変モデル。
@freezed
abstract class ExportMetadata with _$ExportMetadata {
  const factory ExportMetadata({
    required int version,
    required DateTime exportedAt,
    required int entryCount,
    required int tagCount,
  }) = _ExportMetadata;

  factory ExportMetadata.fromJson(Map<String, dynamic> json) =>
      _$ExportMetadataFromJson(json);
}
