import 'package:hive_ce/hive.dart';
import 'package:holo/env/env.dart';
import 'package:json_annotation/json_annotation.dart';

part 'image.g.dart';

/// 图片信息数据类，包含不同尺寸的图片URL
@HiveType(typeId: 7)
@JsonSerializable()
class Image {
  static final String imgServerUrl = Env.imgServerUrl;
  static final String defaultImgServerHost = "lain.bgm.tv";

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
    final temp = _small?.replaceAll(
      defaultImgServerHost,
      Uri.parse(imgServerUrl).host,
    );
    return temp?.contains('https') == true
        ? temp
        : temp?.replaceFirst("http", "https");
  }

  String? get large {
    final temp = _large?.replaceAll(
      defaultImgServerHost,
      Uri.parse(imgServerUrl).host,
    );
    return temp?.contains('https') == true
        ? temp
        : temp?.replaceFirst("http", "https");
  }

  String? get medium {
    final temp = _medium?.replaceAll(
      defaultImgServerHost,
      Uri.parse(imgServerUrl).host,
    );
    return temp?.contains('https') == true
        ? temp
        : temp?.replaceFirst("http", "https");
  }

  String? get grid {
    final temp = _grid?.replaceAll(
      defaultImgServerHost,
      Uri.parse(imgServerUrl).host,
    );
    return temp?.contains('https') == true
        ? temp
        : temp?.replaceFirst("http", "https");
  }

  const Image({String? small, String? large, String? medium, String? grid})
    : _small = small,
      _large = large,
      _medium = medium,
      _grid = grid;

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  Map<String, dynamic> toJson() => _$ImageToJson(this);
}
