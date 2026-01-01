import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/media.dart';

part 'match_result.g.dart';

@JsonSerializable()
class MatchResult {
  final Media media;
  final double score;

  const MatchResult({required this.media, required this.score});

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$MatchResultToJson(this);
}
