// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'related_work.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelatedWork _$RelatedWorkFromJson(Map<String, dynamic> json) => RelatedWork(
  name: json['name'] as String,
  nameCn: json['name_cn'] as String,
  relation: json['relation'] as String,
  type: (json['type'] as num).toInt(),
  id: (json['id'] as num).toInt(),
  images: json['images'] == null
      ? null
      : Image.fromJson(json['images'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RelatedWorkToJson(RelatedWork instance) =>
    <String, dynamic>{
      'images': instance.images,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'relation': instance.relation,
      'type': instance.type,
      'id': instance.id,
    };
