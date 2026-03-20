// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExportMetadata {

 int get version; DateTime get exportedAt; int get entryCount; int get tagCount;
/// Create a copy of ExportMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportMetadataCopyWith<ExportMetadata> get copyWith => _$ExportMetadataCopyWithImpl<ExportMetadata>(this as ExportMetadata, _$identity);

  /// Serializes this ExportMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportMetadata&&(identical(other.version, version) || other.version == version)&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.tagCount, tagCount) || other.tagCount == tagCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,exportedAt,entryCount,tagCount);

@override
String toString() {
  return 'ExportMetadata(version: $version, exportedAt: $exportedAt, entryCount: $entryCount, tagCount: $tagCount)';
}


}

/// @nodoc
abstract mixin class $ExportMetadataCopyWith<$Res>  {
  factory $ExportMetadataCopyWith(ExportMetadata value, $Res Function(ExportMetadata) _then) = _$ExportMetadataCopyWithImpl;
@useResult
$Res call({
 int version, DateTime exportedAt, int entryCount, int tagCount
});




}
/// @nodoc
class _$ExportMetadataCopyWithImpl<$Res>
    implements $ExportMetadataCopyWith<$Res> {
  _$ExportMetadataCopyWithImpl(this._self, this._then);

  final ExportMetadata _self;
  final $Res Function(ExportMetadata) _then;

/// Create a copy of ExportMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? exportedAt = null,Object? entryCount = null,Object? tagCount = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,exportedAt: null == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,tagCount: null == tagCount ? _self.tagCount : tagCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExportMetadata].
extension ExportMetadataPatterns on ExportMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExportMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExportMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExportMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ExportMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExportMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ExportMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  DateTime exportedAt,  int entryCount,  int tagCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExportMetadata() when $default != null:
return $default(_that.version,_that.exportedAt,_that.entryCount,_that.tagCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  DateTime exportedAt,  int entryCount,  int tagCount)  $default,) {final _that = this;
switch (_that) {
case _ExportMetadata():
return $default(_that.version,_that.exportedAt,_that.entryCount,_that.tagCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  DateTime exportedAt,  int entryCount,  int tagCount)?  $default,) {final _that = this;
switch (_that) {
case _ExportMetadata() when $default != null:
return $default(_that.version,_that.exportedAt,_that.entryCount,_that.tagCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExportMetadata implements ExportMetadata {
  const _ExportMetadata({required this.version, required this.exportedAt, required this.entryCount, required this.tagCount});
  factory _ExportMetadata.fromJson(Map<String, dynamic> json) => _$ExportMetadataFromJson(json);

@override final  int version;
@override final  DateTime exportedAt;
@override final  int entryCount;
@override final  int tagCount;

/// Create a copy of ExportMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExportMetadataCopyWith<_ExportMetadata> get copyWith => __$ExportMetadataCopyWithImpl<_ExportMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExportMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExportMetadata&&(identical(other.version, version) || other.version == version)&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.tagCount, tagCount) || other.tagCount == tagCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,exportedAt,entryCount,tagCount);

@override
String toString() {
  return 'ExportMetadata(version: $version, exportedAt: $exportedAt, entryCount: $entryCount, tagCount: $tagCount)';
}


}

/// @nodoc
abstract mixin class _$ExportMetadataCopyWith<$Res> implements $ExportMetadataCopyWith<$Res> {
  factory _$ExportMetadataCopyWith(_ExportMetadata value, $Res Function(_ExportMetadata) _then) = __$ExportMetadataCopyWithImpl;
@override @useResult
$Res call({
 int version, DateTime exportedAt, int entryCount, int tagCount
});




}
/// @nodoc
class __$ExportMetadataCopyWithImpl<$Res>
    implements _$ExportMetadataCopyWith<$Res> {
  __$ExportMetadataCopyWithImpl(this._self, this._then);

  final _ExportMetadata _self;
  final $Res Function(_ExportMetadata) _then;

/// Create a copy of ExportMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? exportedAt = null,Object? entryCount = null,Object? tagCount = null,}) {
  return _then(_ExportMetadata(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,exportedAt: null == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,tagCount: null == tagCount ? _self.tagCount : tagCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
