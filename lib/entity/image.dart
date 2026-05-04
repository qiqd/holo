import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'image.g.dart';

/// 图片信息数据类，包含不同尺寸的图片URL
@HiveType(typeId: 7)
@JsonSerializable()
class Image {
  /// 小尺寸图片URL
  @HiveField(0)
  final String? small;

  /// 网格尺寸图片URL
  @HiveField(1)
  final String? grid;

  /// 大尺寸图片URL
  @HiveField(2)
  final String? large;

  /// 中等尺寸图片URL
  @HiveField(3)
  final String? medium;

  const Image({this.small, this.grid, this.large, this.medium});

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  Map<String, dynamic> toJson() => _$ImageToJson(this);
}
