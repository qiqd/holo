// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

History _$HistoryFromJson(Map<String, dynamic> json) => History(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  lastViewAt: json['lastViewAt'] == null
      ? null
      : DateTime.parse(json['lastViewAt'] as String),
  position: (json['position'] as num?)?.toInt() ?? 0,
  isLove: json['isLove'] as bool? ?? false,
  imgUrl: json['imgUrl'] as String,
  episodeIndex: (json['episodeIndex'] as num?)?.toInt() ?? 0,
  lineIndex: (json['lineIndex'] as num?)?.toInt() ?? 0,
  isSync: json['isSync'] as bool? ?? false,
  isPlaybackHistory: json['isHistory'] as bool? ?? true,
);

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'lastViewAt': instance.lastViewAt?.toIso8601String(),
  'position': instance.position,
  'imgUrl': instance.imgUrl,
  'isLove': instance.isLove,
  'episodeIndex': instance.episodeIndex,
  'lineIndex': instance.lineIndex,
  'isSync': instance.isSync,
  'isHistory': instance.isPlaybackHistory,
};
