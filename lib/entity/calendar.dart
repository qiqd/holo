import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'calendar.g.dart';

/// 评分信息
@JsonSerializable()
class Rating {
  final int? total;
  final double? score;

  const Rating({this.total, this.score});

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

  Map<String, dynamic> toJson() => _$RatingToJson(this);
}

/// 日历数据类，对应 Bangumi 番组日历 API 返回的数组元素
@JsonSerializable()
class Calendar {
  final List<Item>? items;

  const Calendar({this.items});

  factory Calendar.fromJson(Map<String, dynamic> json) =>
      _$CalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarToJson(this);
}

/// 番组条目信息
@JsonSerializable()
class Item {
  final int? id;
  final String? url;
  final int? type;
  final String? name;
  @JsonKey(name: 'name_cn')
  final String? nameCn;
  final String? summary;
  @JsonKey(name: 'air_date')
  String? airDate;
  @JsonKey(name: 'air_weekday')
  final int? airWeekday;
  final Rating? rating;
  final int? rank;
  final Image? images;

  Item({
    this.id,
    this.url,
    this.type,
    this.name,
    this.nameCn,
    this.summary,
    this.airDate,
    this.airWeekday,
    this.rating,
    this.rank,
    this.images,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
