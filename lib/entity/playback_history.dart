import 'package:json_annotation/json_annotation.dart';

part 'playback_history.g.dart';

@JsonSerializable()
class PlaybackHistory {
  String? id;
  int subId;
  String title;
  String imgUrl;
  DateTime lastPlaybackAt;
  DateTime createdAt;
  int position;
  String? airDate;
  int episodeIndex;
  int lineIndex;
  bool isSync;
  PlaybackHistory({
    this.id,
    required this.subId,
    required this.title,
    required this.lastPlaybackAt,
    required this.createdAt,
    this.airDate,
    required this.imgUrl,
    this.position = 0,
    this.episodeIndex = 0,
    this.lineIndex = 0,
    this.isSync = false,
  });
  factory PlaybackHistory.fromJson(Map<String, dynamic> json) =>
      _$PlaybackHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PlaybackHistoryToJson(this);
}
