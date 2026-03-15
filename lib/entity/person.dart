import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {
  /// 人物图片
  final Image? images;

  /// 人物名称
  final String? name;

  /// 人物关系
  final String? relation;

  /// 人物职业
  final List<String>? career;

  /// 人物类型
  final int? type;

  /// 人物ID
  final int? id;

  /// 人物负责的剧集
  final String? eps;

  Person({
    this.images,
    this.name,
    this.relation,
    this.career,
    this.type,
    this.id,
    this.eps,
  });

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
