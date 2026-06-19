import 'package:hive_ce/hive.dart';
import 'package:holo/env/env.dart';
import 'package:json_annotation/json_annotation.dart';

part 'image.g.dart';

/// 图片信息数据类，包含不同尺寸的图片URL
@HiveType(typeId: 7)
@JsonSerializable()
class Image {
  static final String defaultImgServerHost = "lain.bgm.tv";
  static final String imgServerUrl = Env.imgServerUrl ?? defaultImgServerHost;

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

  String? get small => _processUrl(_small);

  String? get large => _processUrl(_large);

  String? get medium => _processUrl(_medium);

  String? get grid => _processUrl(_grid);

  const Image({String? small, String? large, String? medium, String? grid})
    : _small = small,
      _large = large,
      _medium = medium,
      _grid = grid;

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  Map<String, dynamic> toJson() => _$ImageToJson(this);

  static String? _processUrl(String? url) {
    if (url == null) return null;
    final temp = url.replaceAll(
      defaultImgServerHost,
      Uri.parse(imgServerUrl).host,
    );
    return temp.contains('https') == true
        ? temp
        : temp.replaceFirst("http", "https");
  }
}
