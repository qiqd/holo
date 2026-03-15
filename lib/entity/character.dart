import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

import 'actor.dart';

part 'character.g.dart';

@JsonSerializable(explicitToJson: true)
class Character {
  /// 角色图片
  final Image? images;

  /// 角色名称
  final String? name;

  /// 角色关系
  final String? relation;

  /// 角色演员
  final List<Actor>? actors;

  /// 角色类型
  final int? type;

  /// 角色ID
  final int? id;

  /// 角色简介
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
