import 'package:hive_ce/hive.dart';
import 'package:holo/entity/anime_info.dart';
import 'package:json_annotation/json_annotation.dart';
part 'daily_broadcast.g.dart';

@HiveType(typeId: 8)
@JsonSerializable()
class DailyBroadcast {
  @HiveField(0)
  final int dayOfWeek;
  @HiveField(1)
  final List<AnimeInfo> items;
  const DailyBroadcast({required this.dayOfWeek, required this.items});
  factory DailyBroadcast.fromJson(Map<String, dynamic> json) =>
      _$DailyBroadcastFromJson(json);
  Map<String, dynamic> toJson() => _$DailyBroadcastToJson(this);
}
