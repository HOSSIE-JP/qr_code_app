// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QrDatabaseModel _$QrDatabaseModelFromJson(Map<String, dynamic> json) =>
    _QrDatabaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$QrDatabaseModelToJson(_QrDatabaseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_QrEntryModel _$QrEntryModelFromJson(Map<String, dynamic> json) =>
    _QrEntryModel(
      id: json['id'] as String,
      databaseId: json['databaseId'] as String? ?? 'default',
      categoryId: json['categoryId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      originalData: _bytesFromJson(json['originalData'] as List<int>),
      dataSize: (json['dataSize'] as num).toInt(),
      chunkCount: (json['chunkCount'] as num?)?.toInt() ?? 1,
      isTextMode: json['isTextMode'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      thumbnail: _nullableBytesFromJson(json['thumbnail'] as List<int>?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$QrEntryModelToJson(_QrEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'databaseId': instance.databaseId,
      'categoryId': instance.categoryId,
      'name': instance.name,
      'description': instance.description,
      'originalData': _bytesToJson(instance.originalData),
      'dataSize': instance.dataSize,
      'chunkCount': instance.chunkCount,
      'isTextMode': instance.isTextMode,
      'isFavorite': instance.isFavorite,
      'thumbnail': _nullableBytesToJson(instance.thumbnail),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'tags': instance.tags,
    };

_CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    _CategoryModel(
      id: json['id'] as String,
      databaseId: json['databaseId'] as String? ?? 'default',
      name: json['name'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CategoryModelToJson(_CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'databaseId': instance.databaseId,
      'name': instance.name,
      'sortOrder': instance.sortOrder,
    };

_TagModel _$TagModelFromJson(Map<String, dynamic> json) => _TagModel(
  id: json['id'] as String,
  databaseId: json['databaseId'] as String? ?? 'default',
  name: json['name'] as String,
  color: (json['color'] as num?)?.toInt() ?? 0xFF6750A4,
);

Map<String, dynamic> _$TagModelToJson(_TagModel instance) => <String, dynamic>{
  'id': instance.id,
  'databaseId': instance.databaseId,
  'name': instance.name,
  'color': instance.color,
};
