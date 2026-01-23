import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart' show Image;

part 'subject.g.dart';

@JsonSerializable()
class Subject {
  final List<Data>? data;
  final int? total;
  final int? limit;
  final int? offset;

  Subject({this.data, this.total, this.limit, this.offset});

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}

@JsonSerializable()
class Data {
  final String? date;
  final String? platform;
  final Image? images;
  final String? image;
  final String? summary;
  final String? name;
  @JsonKey(name: 'name_cn')
  final String? nameCn;
  final List<Tag>? tags;
  final List<InfoBox>? infobox;
  final Rating? rating;
  final Collection? collection;
  final int? id;
  final int? eps;
  @JsonKey(name: 'meta_tags')
  final List<String>? metaTags;
  final int? volumes;
  final bool? series;
  final bool? locked;
  final bool? nsfw;
  final int? type;
  String? sourceName;
  Data({
    this.date,
    this.platform,
    this.images,
    this.image,
    this.summary,
    this.name,
    this.nameCn,
    this.tags,
    this.infobox,
    this.rating,
    this.collection,
    this.id,
    this.eps,
    this.metaTags,
    this.volumes,
    this.series,
    this.locked,
    this.nsfw,
    this.type,
    this.sourceName,
  });

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

  Map<String, dynamic> toJson() => _$DataToJson(this);
}

@JsonSerializable()
class Tag {
  final String? name;
  final int? count;
  @JsonKey(name: 'total_cont')
  final int? totalCont;

  Tag({this.name, this.count, this.totalCont});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);
}

@JsonSerializable()
class InfoBox {
  final String? key;
  final dynamic value;

  InfoBox({this.key, this.value});

  factory InfoBox.fromJson(Map<String, dynamic> json) =>
      _$InfoBoxFromJson(json);

  Map<String, dynamic> toJson() => _$InfoBoxToJson(this);
}

@JsonSerializable()
class Rating {
  final int? rank;
  final int? total;
  final Count? count;
  final double? score;

  Rating({this.rank, this.total, this.count, this.score});

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

  Map<String, dynamic> toJson() => _$RatingToJson(this);
}

@JsonSerializable()
class Count {
  @JsonKey(name: '1')
  final int? one;
  @JsonKey(name: '2')
  final int? two;
  @JsonKey(name: '3')
  final int? three;
  @JsonKey(name: '4')
  final int? four;
  @JsonKey(name: '5')
  final int? five;
  @JsonKey(name: '6')
  final int? six;
  @JsonKey(name: '7')
  final int? seven;
  @JsonKey(name: '8')
  final int? eight;
  @JsonKey(name: '9')
  final int? nine;
  @JsonKey(name: '10')
  final int? ten;

  Count({
    this.one,
    this.two,
    this.three,
    this.four,
    this.five,
    this.six,
    this.seven,
    this.eight,
    this.nine,
    this.ten,
  });

  factory Count.fromJson(Map<String, dynamic> json) => _$CountFromJson(json);

  Map<String, dynamic> toJson() => _$CountToJson(this);
}

@JsonSerializable()
class Collection {
  @JsonKey(name: 'on_hold')
  final int? onHold;
  final int? dropped;
  final int? wish;
  final int? collect;
  final int? doing;

  Collection({this.onHold, this.dropped, this.wish, this.collect, this.doing});

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);
}
