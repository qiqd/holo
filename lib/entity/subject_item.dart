import 'package:holo/entity/image.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
part 'subject_item.g.dart';

@HiveType(typeId: 4)
@JsonSerializable()
class SubjectItem {
  @HiveField(0)
  int id;
  @HiveField(1)
  String title;
  @HiveField(2)
  Image images;
  @HiveField(3)
  String summary;
  @HiveField(4)
  int ratingCount;
  @HiveField(5)
  int totalEpisodes;
  @HiveField(6)
  List<String> metaTags;
  @HiveField(7)
  int? currentEpisode;
  @HiveField(8)
  String? airTime;
  @HiveField(9)
  String? airDate;
  @HiveField(10)
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
