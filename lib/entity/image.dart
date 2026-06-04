import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'image.g.dart';

/// 图片信息数据类，包含不同尺寸的图片URL
@HiveType(typeId: 7)
@JsonSerializable()
class Image {
  static const String imgServerUrl = String.fromEnvironment("IMG_SERVER_URL");

  /// 小尺寸图片URL
  @HiveField(0)
  final String? _small;

  /// 大尺寸图片URL
  @HiveField(1)
  final String? _large;

  /// 中等尺寸图片URL
  @HiveField(2)
  final String? _medium;

  /// 宫格尺寸图片URL
  @HiveField(3)
  final String? _grid;

  String? get small {
    return _small?.replaceAll("https://lain.bgm.tv", imgServerUrl);
  }

  String? get large {
    return _large?.replaceAll("https://lain.bgm.tv", imgServerUrl);
  }

  String? get medium {
    return _medium?.replaceAll("https://lain.bgm.tv", imgServerUrl);
  }

  String? get grid {
    return _grid?.replaceAll("https://lain.bgm.tv", imgServerUrl);
  }

  const Image({String? small, String? large, String? medium, String? grid})
    : _small = small,
      _large = large,
      _medium = medium,
      _grid = grid;

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  Map<String, dynamic> toJson() => _$ImageToJson(this);
}
