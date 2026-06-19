import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daily_mantra.g.dart';

@HiveType(typeId: 12)
@JsonSerializable(explicitToJson: true)
class DailyMantra {
  @HiveField(0)
  String mantra;
  @HiveField(1)
  String type;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  String? who;
  @HiveField(4)
  String from;

  DailyMantra({
    required this.mantra,
    required this.type,
    required this.date,
    required this.from,
    this.who,
  });

  factory DailyMantra.fromJson(Map<String, dynamic> json) =>
      _$DailyMantraFromJson(json);

  Map<String, dynamic> toJson() => _$DailyMantraToJson(this);
}
