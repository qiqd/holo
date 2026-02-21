import 'package:json_annotation/json_annotation.dart';

part 'media.g.dart';

/// 媒体信息类
/// 包含媒体的基本信息
@JsonSerializable()
class Media {
  /// 媒体ID
  String? id;

  /// 媒体标题
  String? title;

  /// 媒体类型
  String? type;

  /// 封面图片URL
  String? coverUrl;

  /// 评分
  double? score;

  /// 构造函数
  /// [id] 媒体ID
  /// [title] 媒体标题
  /// [type] 媒体类型
  /// [coverUrl] 封面图片URL
  /// [score] 评分，默认为0
  Media({this.id, this.title, this.type, this.coverUrl, this.score = 0});

  /// 从JSON格式创建Media实例
  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$MediaToJson(this);
}

/// 剧集线路类
/// 包含一个线路的剧集列表
@JsonSerializable()
class Line {
  /// 线路名称
  String? name;

  /// 剧集列表
  List<String>? episodes;

  /// 构造函数
  /// [name] 线路名称
  /// [episodes] 剧集列表
  Line({this.name, this.episodes});

  /// 从JSON格式创建Line实例
  factory Line.fromJson(Map<String, dynamic> json) => _$LineFromJson(json);

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$LineToJson(this);
}

/// 媒体详情类
/// 包含媒体的详细信息和剧集线路
@JsonSerializable()
class Detail {
  /// 媒体信息
  Media? media;

  /// 剧集线路列表
  List<Line>? lines;

  /// 从JSON格式创建Detail实例
  factory Detail.fromJson(Map<String, dynamic> json) => _$DetailFromJson(json);

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$DetailToJson(this);

  /// 构造函数
  /// [media] 媒体信息
  /// [lines] 剧集线路列表
  Detail({this.media, this.lines});
}
