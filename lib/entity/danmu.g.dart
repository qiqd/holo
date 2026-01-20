// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Danmu _$DanmuFromJson(Map<String, dynamic> json) => Danmu(
  count: (json['count'] as num?)?.toInt(),
  comments: (json['comments'] as List<dynamic>?)
      ?.map((e) => DanmuItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DanmuToJson(Danmu instance) => <String, dynamic>{
  'count': instance.count,
  'comments': instance.comments?.map((e) => e.toJson()).toList(),
};

DanmuItem _$DanmuItemFromJson(Map<String, dynamic> json) => DanmuItem(
  cid: (json['cid'] as num?)?.toInt(),
  type: (json['type'] as num?)?.toInt(),
  time: (json['time'] as num?)?.toDouble(),
  text: json['text'] as String?,
  color: (json['color'] as num?)?.toInt(),
  t: (json['t'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DanmuItemToJson(DanmuItem instance) => <String, dynamic>{
  'cid': instance.cid,
  'type': instance.type,
  'time': instance.time,
  'text': instance.text,
  'color': instance.color,
  't': instance.t,
};
