import 'package:holo/entity/image.dart';
import 'package:json_annotation/json_annotation.dart';
part 'subject_item.g.dart';

@JsonSerializable()
class SubjectItem {
  int id;
  String title;
  Image images;
  String summary;
  int ratingCount;
  int totalEpisodes;
  List<String> metaTags;

  /// -1 未放送
  int? currentEpisode;
  String? airTime;
  String? airDate;
  double? rating;

  SubjectItem({
    required this.id,
    required this.title,
    required this.images,
    required this.summary,
    required this.ratingCount,
    required this.totalEpisodes,
    required this.metaTags,
    this.currentEpisode,
    this.airTime,
    this.airDate,
    this.rating,
  });
  factory SubjectItem.fromJson(Map<String, dynamic> json) =>
      _$SubjectItemFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectItemToJson(this);
}
