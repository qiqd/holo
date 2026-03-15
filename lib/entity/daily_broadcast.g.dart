// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_broadcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyBroadcast _$DailyBroadcastFromJson(Map<String, dynamic> json) =>
    DailyBroadcast(
      weekOfDay: (json['weekOfDay'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => SubjectItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DailyBroadcastToJson(DailyBroadcast instance) =>
    <String, dynamic>{'weekOfDay': instance.weekOfDay, 'items': instance.items};
