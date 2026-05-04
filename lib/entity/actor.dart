import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'actor.g.dart';

@HiveType(typeId: 10)
@JsonSerializable(explicitToJson: true)
class Actor {
  @HiveField(0)
  final Image? images;
  @HiveField(1)
  final String? name;
  @HiveField(2)
  final String? shortSummary;
  @HiveField(3)
  final List<String>? career;
  @HiveField(4)
  final int? id;
  @HiveField(5)
  final int? type;
  @HiveField(6)
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
