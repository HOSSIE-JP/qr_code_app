// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportMetadata _$ExportMetadataFromJson(Map<String, dynamic> json) =>
    _ExportMetadata(
      version: (json['version'] as num).toInt(),
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      entryCount: (json['entryCount'] as num).toInt(),
      tagCount: (json['tagCount'] as num).toInt(),
    );

Map<String, dynamic> _$ExportMetadataToJson(_ExportMetadata instance) =>
    <String, dynamic>{
      'version': instance.version,
      'exportedAt': instance.exportedAt.toIso8601String(),
      'entryCount': instance.entryCount,
      'tagCount': instance.tagCount,
    };
