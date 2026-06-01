import 'package:hive_ce/hive.dart';
import 'package:holo/entity/image.dart';
import 'package:json_annotation/json_annotation.dart';
part 'anime_info.g.dart';

@HiveType(typeId: 11)
@JsonSerializable()
class AnimeInfo {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final Image images;
  @HiveField(3)
  String? summary;
  @HiveField(4)
  int? ratingCount;
  @HiveField(5)
  double? rating;
  @HiveField(6)
  int? episodes;
  @HiveField(7)
  List<String> genres;
  @HiveField(8)
  DateTime? airDateTime;
  @HiveField(9)
  String? type;
  @HiveField(10)
  int? latestEpisode;
  AnimeInfo({
    required this.id,
    required this.title,
    required this.images,
    this.episodes,
    this.latestEpisode,
    this.type,
    this.summary,
    this.genres = const [],
    this.ratingCount,
    this.rating,
    this.airDateTime,
  });

  factory AnimeInfo.fromJson(Map<String, dynamic> json) =>
      _$AnimeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AnimeInfoToJson(this);
}
