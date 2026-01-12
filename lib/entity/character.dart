import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

import 'actor.dart';

part 'character.g.dart';

@JsonSerializable(explicitToJson: true)
class Character {
  final Image? images;
  final String? name;
  final String? relation;
  final List<Actor>? actors;
  final int? type;
  final int? id;
  final String? summary;
  const Character({
    this.images,
    this.name,
    this.relation,
    this.actors,
    this.type,
    this.id,
    this.summary,
  });

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);

  Map<String, dynamic> toJson() => _$CharacterToJson(this);
}
