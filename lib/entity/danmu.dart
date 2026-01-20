import 'package:json_annotation/json_annotation.dart';

part 'danmu.g.dart';

@JsonSerializable(explicitToJson: true)
class Danmu {
  int? count;
  List<DanmuItem>? comments;
  Danmu({this.count, this.comments});

  factory Danmu.fromJson(Map<String, dynamic> json) => _$DanmuFromJson(json);

  Map<String, dynamic> toJson() => _$DanmuToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DanmuItem {
  int? cid;

  /// 评论类型 1: 普通弹幕 4:底部弹幕  5: 顶部弹幕
  int? type;

  /// 弹幕出现时间，单位秒
  double? time;

  /// 弹幕内容
  String? text;

  /// 32位整数颜色值
  int? color;
  double? t;

  DanmuItem({this.cid, this.type, this.time, this.text, this.color, this.t});

  factory DanmuItem.fromJson(Map<String, dynamic> json) =>
      _$DanmuItemFromJson(json);

  Map<String, dynamic> toJson() => _$DanmuItemToJson(this);
}
