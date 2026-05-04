// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_var_episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogVarEpisode _$LogVarEpisodeFromJson(Map<String, dynamic> json) =>
    LogVarEpisode(
      animeId: (json['animeId'] as num?)?.toInt(),
      animeTitle: json['animeTitle'] as String?,
      type: json['type'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => EpisodeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LogVarEpisodeToJson(LogVarEpisode instance) =>
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
