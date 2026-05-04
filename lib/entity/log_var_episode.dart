import 'package:json_annotation/json_annotation.dart';

part 'log_var_episode.g.dart';

@JsonSerializable()
class LogVarEpisode {
  int? animeId;
  String? animeTitle;
  String? type;
  List<EpisodeItem>? episodes;
  LogVarEpisode({this.animeId, this.animeTitle, this.type, this.episodes});
  factory LogVarEpisode.fromJson(Map<String, dynamic> json) =>
      _$LogVarEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$LogVarEpisodeToJson(this);
}

@JsonSerializable()
class EpisodeItem {
  int? episodeId;
  String? episodeTitle;
  EpisodeItem({this.episodeId, this.episodeTitle});
  factory EpisodeItem.fromJson(Map<String, dynamic> json) =>
      _$EpisodeItemFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeItemToJson(this);
}
