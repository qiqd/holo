// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackHistory _$PlaybackHistoryFromJson(Map<String, dynamic> json) =>
    PlaybackHistory(
      id: json['id'] as String?,
      subId: (json['subId'] as num).toInt(),
      title: json['title'] as String,
      lastPlaybackAt: DateTime.parse(json['lastPlaybackAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      airDate: json['airDate'] as String?,
      imgUrl: json['imgUrl'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      episodeIndex: (json['episodeIndex'] as num?)?.toInt() ?? 0,
      lineIndex: (json['lineIndex'] as num?)?.toInt() ?? 0,
      isSync: json['isSync'] as bool? ?? false,
    );

Map<String, dynamic> _$PlaybackHistoryToJson(PlaybackHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subId': instance.subId,
      'title': instance.title,
      'imgUrl': instance.imgUrl,
      'lastPlaybackAt': instance.lastPlaybackAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'position': instance.position,
      'airDate': instance.airDate,
      'episodeIndex': instance.episodeIndex,
      'lineIndex': instance.lineIndex,
      'isSync': instance.isSync,
    };
