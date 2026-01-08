import 'package:json_annotation/json_annotation.dart';

part 'logvar_episode.g.dart';

@JsonSerializable()
class LogvarEpisode {
  int? animeId;
  String? animeTitle;
  String? type;
  List<EpisodeItem>? episodes;
  LogvarEpisode({this.animeId, this.animeTitle, this.type, this.episodes});
  factory LogvarEpisode.fromJson(Map<String, dynamic> json) =>
      _$LogvarEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$LogvarEpisodeToJson(this);
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
