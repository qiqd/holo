import 'package:holo/entity/subject_item.dart';
import 'package:json_annotation/json_annotation.dart';
part 'daily_broadcast.g.dart';

@JsonSerializable()
class DailyBroadcast {
  final int weekOfDay;
  final List<SubjectItem> items;
  const DailyBroadcast({required this.weekOfDay, required this.items});
  factory DailyBroadcast.fromJson(Map<String, dynamic> json) =>
      _$DailyBroadcastFromJson(json);
  Map<String, dynamic> toJson() => _$DailyBroadcastToJson(this);
}
