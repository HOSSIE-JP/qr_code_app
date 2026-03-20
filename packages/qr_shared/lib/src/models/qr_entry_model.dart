import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_entry_model.freezed.dart';
part 'qr_entry_model.g.dart';

/// QR データベース（コレクション）の不変モデル。
@freezed
abstract class QrDatabaseModel with _$QrDatabaseModel {
  const factory QrDatabaseModel({
    required String id,
    required String name,
    @Default('') String description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _QrDatabaseModel;

  factory QrDatabaseModel.fromJson(Map<String, dynamic> json) =>
      _$QrDatabaseModelFromJson(json);
}

/// QR エントリの不変モデル。
///
/// [originalData] が空（長さ 0）の場合は QR コード未登録のエントリとして扱う。
/// [isTextMode] が true の場合、[originalData] は UTF-8 エンコード済みの
/// プレーンテキストであり、QR コードには文字列をそのまま埋め込む。
/// false の場合は base64 エンコードした標準 QR コードとして表示する。
@freezed
abstract class QrEntryModel with _$QrEntryModel {
  const QrEntryModel._();

  const factory QrEntryModel({
    required String id,

    /// 所属するデータベースの ID。
    @Default('default') String databaseId,
    String? categoryId,
    required String name,
    @Default('') String description,
    @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
    required Uint8List originalData,
    required int dataSize,
    @Default(1) int chunkCount,

    /// テキストモードかどうか。
    @Default(false) bool isTextMode,

    /// お気に入りフラグ。
    @Default(false) bool isFavorite,
    @JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson)
    Uint8List? thumbnail,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<TagModel> tags,
  }) = _QrEntryModel;

  factory QrEntryModel.fromJson(Map<String, dynamic> json) =>
      _$QrEntryModelFromJson(json);

  /// QR コードのデータが登録されているかどうか。
  bool get hasQrData => dataSize > 0;
}

/// カテゴリ情報を表現する不変モデル。
@freezed
abstract class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,

    /// 所属するデータベースの ID。
    @Default('default') String databaseId,
    required String name,
    @Default(0) int sortOrder,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}

/// タグ情報を表現する不変モデル。
@freezed
abstract class TagModel with _$TagModel {
  const factory TagModel({
    required String id,

    /// 所属するデータベースの ID。
    @Default('default') String databaseId,
    required String name,
    @Default(0xFF6750A4) int color,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
}

Uint8List _bytesFromJson(List<int> json) => Uint8List.fromList(json);
List<int> _bytesToJson(Uint8List bytes) => bytes.toList();
Uint8List? _nullableBytesFromJson(List<int>? json) =>
    json != null ? Uint8List.fromList(json) : null;
List<int>? _nullableBytesToJson(Uint8List? bytes) => bytes?.toList();
