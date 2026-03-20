// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QrDatabaseModel {

 String get id; String get name; String get description; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of QrDatabaseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrDatabaseModelCopyWith<QrDatabaseModel> get copyWith => _$QrDatabaseModelCopyWithImpl<QrDatabaseModel>(this as QrDatabaseModel, _$identity);

  /// Serializes this QrDatabaseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrDatabaseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,createdAt,updatedAt);

@override
String toString() {
  return 'QrDatabaseModel(id: $id, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $QrDatabaseModelCopyWith<$Res>  {
  factory $QrDatabaseModelCopyWith(QrDatabaseModel value, $Res Function(QrDatabaseModel) _then) = _$QrDatabaseModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$QrDatabaseModelCopyWithImpl<$Res>
    implements $QrDatabaseModelCopyWith<$Res> {
  _$QrDatabaseModelCopyWithImpl(this._self, this._then);

  final QrDatabaseModel _self;
  final $Res Function(QrDatabaseModel) _then;

/// Create a copy of QrDatabaseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [QrDatabaseModel].
extension QrDatabaseModelPatterns on QrDatabaseModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QrDatabaseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QrDatabaseModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QrDatabaseModel value)  $default,){
final _that = this;
switch (_that) {
case _QrDatabaseModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QrDatabaseModel value)?  $default,){
final _that = this;
switch (_that) {
case _QrDatabaseModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QrDatabaseModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _QrDatabaseModel():
return $default(_that.id,_that.name,_that.description,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _QrDatabaseModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QrDatabaseModel implements QrDatabaseModel {
  const _QrDatabaseModel({required this.id, required this.name, this.description = '', required this.createdAt, required this.updatedAt});
  factory _QrDatabaseModel.fromJson(Map<String, dynamic> json) => _$QrDatabaseModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of QrDatabaseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QrDatabaseModelCopyWith<_QrDatabaseModel> get copyWith => __$QrDatabaseModelCopyWithImpl<_QrDatabaseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QrDatabaseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QrDatabaseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,createdAt,updatedAt);

@override
String toString() {
  return 'QrDatabaseModel(id: $id, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$QrDatabaseModelCopyWith<$Res> implements $QrDatabaseModelCopyWith<$Res> {
  factory _$QrDatabaseModelCopyWith(_QrDatabaseModel value, $Res Function(_QrDatabaseModel) _then) = __$QrDatabaseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$QrDatabaseModelCopyWithImpl<$Res>
    implements _$QrDatabaseModelCopyWith<$Res> {
  __$QrDatabaseModelCopyWithImpl(this._self, this._then);

  final _QrDatabaseModel _self;
  final $Res Function(_QrDatabaseModel) _then;

/// Create a copy of QrDatabaseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_QrDatabaseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$QrEntryModel {

 String get id;/// 所属するデータベースの ID。
 String get databaseId; String? get categoryId; String get name; String get description;@JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson) Uint8List get originalData; int get dataSize; int get chunkCount;/// テキストモードかどうか。
 bool get isTextMode;/// お気に入りフラグ。
 bool get isFavorite;@JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson) Uint8List? get thumbnail; DateTime get createdAt; DateTime get updatedAt; List<TagModel> get tags;
/// Create a copy of QrEntryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrEntryModelCopyWith<QrEntryModel> get copyWith => _$QrEntryModelCopyWithImpl<QrEntryModel>(this as QrEntryModel, _$identity);

  /// Serializes this QrEntryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.databaseId, databaseId) || other.databaseId == databaseId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.originalData, originalData)&&(identical(other.dataSize, dataSize) || other.dataSize == dataSize)&&(identical(other.chunkCount, chunkCount) || other.chunkCount == chunkCount)&&(identical(other.isTextMode, isTextMode) || other.isTextMode == isTextMode)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&const DeepCollectionEquality().equals(other.thumbnail, thumbnail)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,databaseId,categoryId,name,description,const DeepCollectionEquality().hash(originalData),dataSize,chunkCount,isTextMode,isFavorite,const DeepCollectionEquality().hash(thumbnail),createdAt,updatedAt,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'QrEntryModel(id: $id, databaseId: $databaseId, categoryId: $categoryId, name: $name, description: $description, originalData: $originalData, dataSize: $dataSize, chunkCount: $chunkCount, isTextMode: $isTextMode, isFavorite: $isFavorite, thumbnail: $thumbnail, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $QrEntryModelCopyWith<$Res>  {
  factory $QrEntryModelCopyWith(QrEntryModel value, $Res Function(QrEntryModel) _then) = _$QrEntryModelCopyWithImpl;
@useResult
$Res call({
 String id, String databaseId, String? categoryId, String name, String description,@JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson) Uint8List originalData, int dataSize, int chunkCount, bool isTextMode, bool isFavorite,@JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson) Uint8List? thumbnail, DateTime createdAt, DateTime updatedAt, List<TagModel> tags
});




}
/// @nodoc
class _$QrEntryModelCopyWithImpl<$Res>
    implements $QrEntryModelCopyWith<$Res> {
  _$QrEntryModelCopyWithImpl(this._self, this._then);

  final QrEntryModel _self;
  final $Res Function(QrEntryModel) _then;

/// Create a copy of QrEntryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? databaseId = null,Object? categoryId = freezed,Object? name = null,Object? description = null,Object? originalData = null,Object? dataSize = null,Object? chunkCount = null,Object? isTextMode = null,Object? isFavorite = null,Object? thumbnail = freezed,Object? createdAt = null,Object? updatedAt = null,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,databaseId: null == databaseId ? _self.databaseId : databaseId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,originalData: null == originalData ? _self.originalData : originalData // ignore: cast_nullable_to_non_nullable
as Uint8List,dataSize: null == dataSize ? _self.dataSize : dataSize // ignore: cast_nullable_to_non_nullable
as int,chunkCount: null == chunkCount ? _self.chunkCount : chunkCount // ignore: cast_nullable_to_non_nullable
as int,isTextMode: null == isTextMode ? _self.isTextMode : isTextMode // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as Uint8List?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<TagModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [QrEntryModel].
extension QrEntryModelPatterns on QrEntryModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QrEntryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QrEntryModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QrEntryModel value)  $default,){
final _that = this;
switch (_that) {
case _QrEntryModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QrEntryModel value)?  $default,){
final _that = this;
switch (_that) {
case _QrEntryModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String databaseId,  String? categoryId,  String name,  String description, @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)  Uint8List originalData,  int dataSize,  int chunkCount,  bool isTextMode,  bool isFavorite, @JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson)  Uint8List? thumbnail,  DateTime createdAt,  DateTime updatedAt,  List<TagModel> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QrEntryModel() when $default != null:
return $default(_that.id,_that.databaseId,_that.categoryId,_that.name,_that.description,_that.originalData,_that.dataSize,_that.chunkCount,_that.isTextMode,_that.isFavorite,_that.thumbnail,_that.createdAt,_that.updatedAt,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String databaseId,  String? categoryId,  String name,  String description, @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)  Uint8List originalData,  int dataSize,  int chunkCount,  bool isTextMode,  bool isFavorite, @JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson)  Uint8List? thumbnail,  DateTime createdAt,  DateTime updatedAt,  List<TagModel> tags)  $default,) {final _that = this;
switch (_that) {
case _QrEntryModel():
return $default(_that.id,_that.databaseId,_that.categoryId,_that.name,_that.description,_that.originalData,_that.dataSize,_that.chunkCount,_that.isTextMode,_that.isFavorite,_that.thumbnail,_that.createdAt,_that.updatedAt,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String databaseId,  String? categoryId,  String name,  String description, @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)  Uint8List originalData,  int dataSize,  int chunkCount,  bool isTextMode,  bool isFavorite, @JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson)  Uint8List? thumbnail,  DateTime createdAt,  DateTime updatedAt,  List<TagModel> tags)?  $default,) {final _that = this;
switch (_that) {
case _QrEntryModel() when $default != null:
return $default(_that.id,_that.databaseId,_that.categoryId,_that.name,_that.description,_that.originalData,_that.dataSize,_that.chunkCount,_that.isTextMode,_that.isFavorite,_that.thumbnail,_that.createdAt,_that.updatedAt,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QrEntryModel extends QrEntryModel {
  const _QrEntryModel({required this.id, this.databaseId = 'default', this.categoryId, required this.name, this.description = '', @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson) required this.originalData, required this.dataSize, this.chunkCount = 1, this.isTextMode = false, this.isFavorite = false, @JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson) this.thumbnail, required this.createdAt, required this.updatedAt, final  List<TagModel> tags = const []}): _tags = tags,super._();
  factory _QrEntryModel.fromJson(Map<String, dynamic> json) => _$QrEntryModelFromJson(json);

@override final  String id;
/// 所属するデータベースの ID。
@override@JsonKey() final  String databaseId;
@override final  String? categoryId;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson) final  Uint8List originalData;
@override final  int dataSize;
@override@JsonKey() final  int chunkCount;
/// テキストモードかどうか。
@override@JsonKey() final  bool isTextMode;
/// お気に入りフラグ。
@override@JsonKey() final  bool isFavorite;
@override@JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson) final  Uint8List? thumbnail;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
 final  List<TagModel> _tags;
@override@JsonKey() List<TagModel> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of QrEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QrEntryModelCopyWith<_QrEntryModel> get copyWith => __$QrEntryModelCopyWithImpl<_QrEntryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QrEntryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QrEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.databaseId, databaseId) || other.databaseId == databaseId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.originalData, originalData)&&(identical(other.dataSize, dataSize) || other.dataSize == dataSize)&&(identical(other.chunkCount, chunkCount) || other.chunkCount == chunkCount)&&(identical(other.isTextMode, isTextMode) || other.isTextMode == isTextMode)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&const DeepCollectionEquality().equals(other.thumbnail, thumbnail)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,databaseId,categoryId,name,description,const DeepCollectionEquality().hash(originalData),dataSize,chunkCount,isTextMode,isFavorite,const DeepCollectionEquality().hash(thumbnail),createdAt,updatedAt,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'QrEntryModel(id: $id, databaseId: $databaseId, categoryId: $categoryId, name: $name, description: $description, originalData: $originalData, dataSize: $dataSize, chunkCount: $chunkCount, isTextMode: $isTextMode, isFavorite: $isFavorite, thumbnail: $thumbnail, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$QrEntryModelCopyWith<$Res> implements $QrEntryModelCopyWith<$Res> {
  factory _$QrEntryModelCopyWith(_QrEntryModel value, $Res Function(_QrEntryModel) _then) = __$QrEntryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String databaseId, String? categoryId, String name, String description,@JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson) Uint8List originalData, int dataSize, int chunkCount, bool isTextMode, bool isFavorite,@JsonKey(fromJson: _nullableBytesFromJson, toJson: _nullableBytesToJson) Uint8List? thumbnail, DateTime createdAt, DateTime updatedAt, List<TagModel> tags
});




}
/// @nodoc
class __$QrEntryModelCopyWithImpl<$Res>
    implements _$QrEntryModelCopyWith<$Res> {
  __$QrEntryModelCopyWithImpl(this._self, this._then);

  final _QrEntryModel _self;
  final $Res Function(_QrEntryModel) _then;

/// Create a copy of QrEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? databaseId = null,Object? categoryId = freezed,Object? name = null,Object? description = null,Object? originalData = null,Object? dataSize = null,Object? chunkCount = null,Object? isTextMode = null,Object? isFavorite = null,Object? thumbnail = freezed,Object? createdAt = null,Object? updatedAt = null,Object? tags = null,}) {
  return _then(_QrEntryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,databaseId: null == databaseId ? _self.databaseId : databaseId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,originalData: null == originalData ? _self.originalData : originalData // ignore: cast_nullable_to_non_nullable
as Uint8List,dataSize: null == dataSize ? _self.dataSize : dataSize // ignore: cast_nullable_to_non_nullable
as int,chunkCount: null == chunkCount ? _self.chunkCount : chunkCount // ignore: cast_nullable_to_non_nullable
as int,isTextMode: null == isTextMode ? _self.isTextMode : isTextMode // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as Uint8List?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<TagModel>,
  ));
}


}


/// @nodoc
mixin _$CategoryModel {

 String get id;/// 所属するデータベースの ID。
 String get databaseId; String get name; int get sortOrder;
/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<CategoryModel> get copyWith => _$CategoryModelCopyWithImpl<CategoryModel>(this as CategoryModel, _$identity);

  /// Serializes this CategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.databaseId, databaseId) || other.databaseId == databaseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,databaseId,name,sortOrder);

@override
String toString() {
  return 'CategoryModel(id: $id, databaseId: $databaseId, name: $name, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CategoryModelCopyWith<$Res>  {
  factory $CategoryModelCopyWith(CategoryModel value, $Res Function(CategoryModel) _then) = _$CategoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String databaseId, String name, int sortOrder
});




}
/// @nodoc
class _$CategoryModelCopyWithImpl<$Res>
    implements $CategoryModelCopyWith<$Res> {
  _$CategoryModelCopyWithImpl(this._self, this._then);

  final CategoryModel _self;
  final $Res Function(CategoryModel) _then;

/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? databaseId = null,Object? name = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,databaseId: null == databaseId ? _self.databaseId : databaseId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryModel].
extension CategoryModelPatterns on CategoryModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String databaseId,  String name,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that.id,_that.databaseId,_that.name,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String databaseId,  String name,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _CategoryModel():
return $default(_that.id,_that.databaseId,_that.name,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String databaseId,  String name,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that.id,_that.databaseId,_that.name,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryModel implements CategoryModel {
  const _CategoryModel({required this.id, this.databaseId = 'default', required this.name, this.sortOrder = 0});
  factory _CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);

@override final  String id;
/// 所属するデータベースの ID。
@override@JsonKey() final  String databaseId;
@override final  String name;
@override@JsonKey() final  int sortOrder;

/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryModelCopyWith<_CategoryModel> get copyWith => __$CategoryModelCopyWithImpl<_CategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.databaseId, databaseId) || other.databaseId == databaseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,databaseId,name,sortOrder);

@override
String toString() {
  return 'CategoryModel(id: $id, databaseId: $databaseId, name: $name, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CategoryModelCopyWith<$Res> implements $CategoryModelCopyWith<$Res> {
  factory _$CategoryModelCopyWith(_CategoryModel value, $Res Function(_CategoryModel) _then) = __$CategoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String databaseId, String name, int sortOrder
});




}
/// @nodoc
class __$CategoryModelCopyWithImpl<$Res>
    implements _$CategoryModelCopyWith<$Res> {
  __$CategoryModelCopyWithImpl(this._self, this._then);

  final _CategoryModel _self;
  final $Res Function(_CategoryModel) _then;

/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? databaseId = null,Object? name = null,Object? sortOrder = null,}) {
  return _then(_CategoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,databaseId: null == databaseId ? _self.databaseId : databaseId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TagModel {

 String get id;/// 所属するデータベースの ID。
 String get databaseId; String get name; int get color;
/// Create a copy of TagModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagModelCopyWith<TagModel> get copyWith => _$TagModelCopyWithImpl<TagModel>(this as TagModel, _$identity);

  /// Serializes this TagModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagModel&&(identical(other.id, id) || other.id == id)&&(identical(other.databaseId, databaseId) || other.databaseId == databaseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,databaseId,name,color);

@override
String toString() {
  return 'TagModel(id: $id, databaseId: $databaseId, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class $TagModelCopyWith<$Res>  {
  factory $TagModelCopyWith(TagModel value, $Res Function(TagModel) _then) = _$TagModelCopyWithImpl;
@useResult
$Res call({
 String id, String databaseId, String name, int color
});




}
/// @nodoc
class _$TagModelCopyWithImpl<$Res>
    implements $TagModelCopyWith<$Res> {
  _$TagModelCopyWithImpl(this._self, this._then);

  final TagModel _self;
  final $Res Function(TagModel) _then;

/// Create a copy of TagModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? databaseId = null,Object? name = null,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,databaseId: null == databaseId ? _self.databaseId : databaseId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TagModel].
extension TagModelPatterns on TagModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TagModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TagModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TagModel value)  $default,){
final _that = this;
switch (_that) {
case _TagModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TagModel value)?  $default,){
final _that = this;
switch (_that) {
case _TagModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String databaseId,  String name,  int color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TagModel() when $default != null:
return $default(_that.id,_that.databaseId,_that.name,_that.color);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String databaseId,  String name,  int color)  $default,) {final _that = this;
switch (_that) {
case _TagModel():
return $default(_that.id,_that.databaseId,_that.name,_that.color);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String databaseId,  String name,  int color)?  $default,) {final _that = this;
switch (_that) {
case _TagModel() when $default != null:
return $default(_that.id,_that.databaseId,_that.name,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TagModel implements TagModel {
  const _TagModel({required this.id, this.databaseId = 'default', required this.name, this.color = 0xFF6750A4});
  factory _TagModel.fromJson(Map<String, dynamic> json) => _$TagModelFromJson(json);

@override final  String id;
/// 所属するデータベースの ID。
@override@JsonKey() final  String databaseId;
@override final  String name;
@override@JsonKey() final  int color;

/// Create a copy of TagModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagModelCopyWith<_TagModel> get copyWith => __$TagModelCopyWithImpl<_TagModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TagModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TagModel&&(identical(other.id, id) || other.id == id)&&(identical(other.databaseId, databaseId) || other.databaseId == databaseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,databaseId,name,color);

@override
String toString() {
  return 'TagModel(id: $id, databaseId: $databaseId, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class _$TagModelCopyWith<$Res> implements $TagModelCopyWith<$Res> {
  factory _$TagModelCopyWith(_TagModel value, $Res Function(_TagModel) _then) = __$TagModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String databaseId, String name, int color
});




}
/// @nodoc
class __$TagModelCopyWithImpl<$Res>
    implements _$TagModelCopyWith<$Res> {
  __$TagModelCopyWithImpl(this._self, this._then);

  final _TagModel _self;
  final $Res Function(_TagModel) _then;

/// Create a copy of TagModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? databaseId = null,Object? name = null,Object? color = null,}) {
  return _then(_TagModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,databaseId: null == databaseId ? _self.databaseId : databaseId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
