import 'package:json_annotation/json_annotation.dart';

part 'subscribe_history.g.dart';

@JsonSerializable()
class SubscribeHistory {
  String? id;
  int subId;
  String title;
  String imgUrl;
  String? airDate;
  DateTime createdAt;
  bool isSync;

  /// 观看状态 0:无状态 1:想看 2:看过 3:在看
  int viewingStatus;
  SubscribeHistory({
    required this.subId,
    this.id,
    required this.title,
    this.airDate,
    required this.createdAt,
    required this.imgUrl,
    this.isSync = false,
    this.viewingStatus = 0,
  });

  factory SubscribeHistory.fromJson(Map<String, dynamic> json) =>
      _$SubscribeHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$SubscribeHistoryToJson(this);
}
