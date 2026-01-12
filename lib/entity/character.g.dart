// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Character _$CharacterFromJson(Map<String, dynamic> json) => Character(
  images: json['images'] == null
      ? null
      : Image.fromJson(json['images'] as Map<String, dynamic>),
  name: json['name'] as String?,
  relation: json['relation'] as String?,
  actors: (json['actors'] as List<dynamic>?)
      ?.map((e) => Actor.fromJson(e as Map<String, dynamic>))
      .toList(),
  type: (json['type'] as num?)?.toInt(),
  id: (json['id'] as num?)?.toInt(),
  summary: json['summary'] as String?,
);

Map<String, dynamic> _$CharacterToJson(Character instance) => <String, dynamic>{
  'images': instance.images?.toJson(),
  'name': instance.name,
  'relation': instance.relation,
  'actors': instance.actors?.map((e) => e.toJson()).toList(),
  'type': instance.type,
  'id': instance.id,
  'summary': instance.summary,
};
