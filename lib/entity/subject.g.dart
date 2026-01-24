// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => Data.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num?)?.toInt(),
  limit: (json['limit'] as num?)?.toInt(),
  offset: (json['offset'] as num?)?.toInt(),
);

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
  'data': instance.data,
  'total': instance.total,
  'limit': instance.limit,
  'offset': instance.offset,
};

Data _$DataFromJson(Map<String, dynamic> json) => Data(
  date: json['date'] as String?,
  platform: json['platform'] as String?,
  images: json['images'] == null
      ? null
      : Image.fromJson(json['images'] as Map<String, dynamic>),
  image: json['image'] as String?,
  summary: json['summary'] as String?,
  name: json['name'] as String?,
  nameCn: json['name_cn'] as String?,
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
      .toList(),
  infobox: (json['infobox'] as List<dynamic>?)
      ?.map((e) => InfoBox.fromJson(e as Map<String, dynamic>))
      .toList(),
  rating: json['rating'] == null
      ? null
      : Rating.fromJson(json['rating'] as Map<String, dynamic>),
  collection: json['collection'] == null
      ? null
      : Collection.fromJson(json['collection'] as Map<String, dynamic>),
  id: (json['id'] as num?)?.toInt(),
  eps: (json['eps'] as num?)?.toInt(),
  metaTags: (json['meta_tags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  volumes: (json['volumes'] as num?)?.toInt(),
  series: json['series'] as bool?,
  locked: json['locked'] as bool?,
  nsfw: json['nsfw'] as bool?,
  type: (json['type'] as num?)?.toInt(),
  sourceName: json['sourceName'] as String?,
);

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
  'date': instance.date,
  'platform': instance.platform,
  'images': instance.images,
  'image': instance.image,
  'summary': instance.summary,
  'name': instance.name,
  'name_cn': instance.nameCn,
  'tags': instance.tags,
  'infobox': instance.infobox,
  'rating': instance.rating,
  'collection': instance.collection,
  'id': instance.id,
  'eps': instance.eps,
  'meta_tags': instance.metaTags,
  'volumes': instance.volumes,
  'series': instance.series,
  'locked': instance.locked,
  'nsfw': instance.nsfw,
  'type': instance.type,
  'sourceName': instance.sourceName,
};

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
  name: json['name'] as String?,
  count: (json['count'] as num?)?.toInt(),
  totalCont: (json['total_cont'] as num?)?.toInt(),
);

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
  'name': instance.name,
  'count': instance.count,
  'total_cont': instance.totalCont,
};

InfoBox _$InfoBoxFromJson(Map<String, dynamic> json) =>
    InfoBox(key: json['key'] as String?, value: json['value']);

Map<String, dynamic> _$InfoBoxToJson(InfoBox instance) => <String, dynamic>{
  'key': instance.key,
  'value': instance.value,
};

Rating _$RatingFromJson(Map<String, dynamic> json) => Rating(
  rank: (json['rank'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toInt(),
  count: json['count'] == null
      ? null
      : Count.fromJson(json['count'] as Map<String, dynamic>),
  score: (json['score'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RatingToJson(Rating instance) => <String, dynamic>{
  'rank': instance.rank,
  'total': instance.total,
  'count': instance.count,
  'score': instance.score,
};

Count _$CountFromJson(Map<String, dynamic> json) => Count(
  one: (json['1'] as num?)?.toInt(),
  two: (json['2'] as num?)?.toInt(),
  three: (json['3'] as num?)?.toInt(),
  four: (json['4'] as num?)?.toInt(),
  five: (json['5'] as num?)?.toInt(),
  six: (json['6'] as num?)?.toInt(),
  seven: (json['7'] as num?)?.toInt(),
  eight: (json['8'] as num?)?.toInt(),
  nine: (json['9'] as num?)?.toInt(),
  ten: (json['10'] as num?)?.toInt(),
);

Map<String, dynamic> _$CountToJson(Count instance) => <String, dynamic>{
  '1': instance.one,
  '2': instance.two,
  '3': instance.three,
  '4': instance.four,
  '5': instance.five,
  '6': instance.six,
  '7': instance.seven,
  '8': instance.eight,
  '9': instance.nine,
  '10': instance.ten,
};

Collection _$CollectionFromJson(Map<String, dynamic> json) => Collection(
  onHold: (json['on_hold'] as num?)?.toInt(),
  dropped: (json['dropped'] as num?)?.toInt(),
  wish: (json['wish'] as num?)?.toInt(),
  collect: (json['collect'] as num?)?.toInt(),
  doing: (json['doing'] as num?)?.toInt(),
);

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'on_hold': instance.onHold,
      'dropped': instance.dropped,
      'wish': instance.wish,
      'collect': instance.collect,
      'doing': instance.doing,
    };
