import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'actor.g.dart';

@JsonSerializable(explicitToJson: true)
class Actor {
  final Image? images;
  final String? name;
  final String? shortSummary;
  final List<String>? career;
  final int? id;
  final int? type;
  final bool? locked;

  const Actor({
    this.images,
    this.name,
    this.shortSummary,
    this.career,
    this.id,
    this.type,
    this.locked,
  });

  factory Actor.fromJson(Map<String, dynamic> json) => _$ActorFromJson(json);

  Map<String, dynamic> toJson() => _$ActorToJson(this);
}
