// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribe_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribeHistory _$SubscribeHistoryFromJson(Map<String, dynamic> json) =>
    SubscribeHistory(
      subId: (json['subId'] as num).toInt(),
      id: json['id'] as String?,
      title: json['title'] as String,
      airDate: json['airDate'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imgUrl: json['imgUrl'] as String,
      isSync: json['isSync'] as bool? ?? false,
    );

Map<String, dynamic> _$SubscribeHistoryToJson(SubscribeHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subId': instance.subId,
      'title': instance.title,
      'imgUrl': instance.imgUrl,
      'airDate': instance.airDate,
      'createdAt': instance.createdAt.toIso8601String(),
      'isSync': instance.isSync,
    };
