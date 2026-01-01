import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'subject_relation.g.dart';

/// 条目关联信息数据类，用于接收Bangumi API返回的条目关联信息JSON数据
/// 对应subject_relation.json文件的数据结构
@JsonSerializable()
class SubjectRelation {
  final Image? images;
  final String? name;
  @JsonKey(name: 'name_cn')
  final String? nameCn;
  final String? relation;
  final int? type;
  final int? id;

  SubjectRelation({
    this.images,
    this.name,
    this.nameCn,
    this.relation,
    this.type,
    this.id,
  });

  factory SubjectRelation.fromJson(Map<String, dynamic> json) =>
      _$SubjectRelationFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectRelationToJson(this);
}
