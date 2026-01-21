// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rule _$RuleFromJson(Map<String, dynamic> json) => Rule(
  name: json['name'] as String,
  logoUrl: json['logoUrl'] as String,
  searchUrl: json['searchUrl'] as String,
  version: json['version'] as String,
  fullSearchUrl: json['fullSearchUrl'] as bool,
  detailUrl: json['detailUrl'] as String,
  playerUrl: json['playerUrl'] as String,
  fullPlayerUrl: json['fullPlayerUrl'] as bool,
  searchSelector: json['searchSelector'] as String,
  fullDetailUrl: json['fullDetailUrl'] as bool,
  lineSelector: json['lineSelector'] as String,
  episodeSelector: json['episodeSelector'] as String,
  playerVideoSelector: json['playerVideoSelector'] as String,
  itemImgSelector: json['itemImgSelector'] as String,
  itemTitleSelector: json['itemTitleSelector'] as String,
  itemIdSelector: json['itemIdSelector'] as String,
  baseUrl: json['baseUrl'] as String,
  itemImgFromSrc: json['itemImgFromSrc'] as bool,
  timeout: (json['timeout'] as num?)?.toInt() ?? 5,
  embedVideoSelector: json['embedVideoSelector'] as String?,
  itemGenreSelector: json['itemGenreSelector'] as String?,
  videoUrlSubsChar: json['videoUrlSubsChar'] as String?,
  updateAt: DateTime.parse(json['updateAt'] as String? ?? '2012-02-27'),
  isEnabled: json['isEnabled'] as bool? ?? true,
  videoElementAttribute: json['videoElementAttribute'] as String?,
  waitForMediaElement: json['waitForMediaElement'] as bool? ?? false,
);

Map<String, dynamic> _$RuleToJson(Rule instance) => <String, dynamic>{
  'name': instance.name,
  'baseUrl': instance.baseUrl,
  'logoUrl': instance.logoUrl,
  'searchUrl': instance.searchUrl,
  'version': instance.version,
  'fullSearchUrl': instance.fullSearchUrl,
  'timeout': instance.timeout,
  'searchSelector': instance.searchSelector,
  'itemImgSelector': instance.itemImgSelector,
  'itemImgFromSrc': instance.itemImgFromSrc,
  'itemTitleSelector': instance.itemTitleSelector,
  'itemIdSelector': instance.itemIdSelector,
  'itemGenreSelector': instance.itemGenreSelector,
  'detailUrl': instance.detailUrl,
  'fullDetailUrl': instance.fullDetailUrl,
  'lineSelector': instance.lineSelector,
  'episodeSelector': instance.episodeSelector,
  'playerUrl': instance.playerUrl,
  'fullPlayerUrl': instance.fullPlayerUrl,
  'playerVideoSelector': instance.playerVideoSelector,
  'embedVideoSelector': instance.embedVideoSelector,
  'videoUrlSubsChar': instance.videoUrlSubsChar,
  'updateAt': instance.updateAt.toIso8601String(),
  'isEnabled': instance.isEnabled,
  'videoElementAttribute': instance.videoElementAttribute,
  'waitForMediaElement': instance.waitForMediaElement,
};
