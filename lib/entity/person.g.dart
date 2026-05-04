// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
  images: json['images'] == null
      ? null
      : Image.fromJson(json['images'] as Map<String, dynamic>),
  name: json['name'] as String?,
  relation: json['relation'] as String?,
  career: (json['career'] as List<dynamic>?)?.map((e) => e as String).toList(),
  type: (json['type'] as num?)?.toInt(),
  id: (json['id'] as num?)?.toInt(),
  eps: json['eps'] as String?,
  actors: (json['actors'] as List<dynamic>?)
      ?.map((e) => Actor.fromJson(e as Map<String, dynamic>))
      .toList(),
  summary: json['summary'] as String?,
);

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
  'images': instance.images,
  'name': instance.name,
  'relation': instance.relation,
  'career': instance.career,
  'actors': instance.actors,
  'type': instance.type,
  'id': instance.id,
  'eps': instance.eps,
  'summary': instance.summary,
};
