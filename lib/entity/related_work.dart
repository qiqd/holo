import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'related_work.g.dart';

/// 条目关联信息数据类，用于接收Bangumi API返回的条目关联信息JSON数据
/// 对应subject_relation.json文件的数据结构
@JsonSerializable()
class RelatedWork {
  final Image? images;
  final String name;
  @JsonKey(name: 'name_cn')
  final String nameCn;
  final String relation;
  final int type;
  final int id;

  RelatedWork({
    required this.name,
    required this.nameCn,
    required this.relation,
    required this.type,
    required this.id,
    this.images,
  });

  factory RelatedWork.fromJson(Map<String, dynamic> json) =>
      _$RelatedWorkFromJson(json);

  Map<String, dynamic> toJson() => _$RelatedWorkToJson(this);
}
