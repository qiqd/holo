// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logvar_episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogvarEpisode _$LogvarEpisodeFromJson(Map<String, dynamic> json) =>
    LogvarEpisode(
      animeId: (json['animeId'] as num?)?.toInt(),
      animeTitle: json['animeTitle'] as String?,
      type: json['type'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => EpisodeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LogvarEpisodeToJson(LogvarEpisode instance) =>
    <String, dynamic>{
      'animeId': instance.animeId,
      'animeTitle': instance.animeTitle,
      'type': instance.type,
      'episodes': instance.episodes,
    };

EpisodeItem _$EpisodeItemFromJson(Map<String, dynamic> json) => EpisodeItem(
  episodeId: (json['episodeId'] as num?)?.toInt(),
  episodeTitle: json['episodeTitle'] as String?,
);

Map<String, dynamic> _$EpisodeItemToJson(EpisodeItem instance) =>
    <String, dynamic>{
      'episodeId': instance.episodeId,
      'episodeTitle': instance.episodeTitle,
    };
