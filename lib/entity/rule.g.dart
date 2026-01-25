// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rule _$RuleFromJson(Map<String, dynamic> json) => Rule(
  name: json['name'] as String? ?? '',
  logoUrl: json['logoUrl'] as String? ?? '',
  searchUrl: json['searchUrl'] as String? ?? '',
  detailUrl: json['detailUrl'] as String? ?? '',
  playerUrl: json['playerUrl'] as String? ?? '',
  searchSelector: json['searchSelector'] as String? ?? '',
  lineSelector: json['lineSelector'] as String? ?? '',
  episodeSelector: json['episodeSelector'] as String? ?? '',
  playerVideoSelector: json['playerVideoSelector'] as String? ?? '',
  itemImgSelector: json['itemImgSelector'] as String? ?? '',
  itemTitleSelector: json['itemTitleSelector'] as String? ?? '',
  itemIdSelector: json['itemIdSelector'] as String? ?? '',
  baseUrl: json['baseUrl'] as String? ?? '',
  fullSearchUrl: json['fullSearchUrl'] as bool? ?? false,
  fullPlayerUrl: json['fullPlayerUrl'] as bool? ?? false,
  fullDetailUrl: json['fullDetailUrl'] as bool? ?? false,
  itemImgFromSrc: json['itemImgFromSrc'] as bool? ?? true,
  waitForMediaElement: json['waitForMediaElement'] as bool? ?? true,
  searchRequestHeaders:
      (json['searchRequestHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  detailRequestHeaders:
      (json['detailRequestHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  playerRequestHeaders:
      (json['playerRequestHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  searchRequestBody:
      (json['searchRequestBody'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  detailRequestBody:
      (json['detailRequestBody'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  playerRequestBody:
      (json['playerRequestBody'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  videoElementAttribute: json['videoElementAttribute'] as String?,
  version: json['version'] as String? ?? '1.0',
  isEnabled: json['isEnabled'] as bool? ?? true,
  timeout: (json['timeout'] as num?)?.toInt() ?? 5,
  isLocal: json['isLocal'] as bool? ?? true,
  searchRequestMethod:
      $enumDecodeNullable(
        _$RequestMethodEnumMap,
        json['searchRequestMethod'],
      ) ??
      RequestMethod.get,
  detailRequestMethod:
      $enumDecodeNullable(
        _$RequestMethodEnumMap,
        json['detailRequestMethod'],
      ) ??
      RequestMethod.get,
  playerRequestMethod:
      $enumDecodeNullable(
        _$RequestMethodEnumMap,
        json['playerRequestMethod'],
      ) ??
      RequestMethod.get,
  embedVideoSelector: json['embedVideoSelector'] as String?,
  itemGenreSelector: json['itemGenreSelector'] as String?,
  videoUrlSubsChar: json['videoUrlSubsChar'] as String?,
)..updateAt = DateTime.parse(json['updateAt'] as String);

Map<String, dynamic> _$RuleToJson(Rule instance) => <String, dynamic>{
  'name': instance.name,
  'baseUrl': instance.baseUrl,
  'logoUrl': instance.logoUrl,
  'version': instance.version,
  'searchUrl': instance.searchUrl,
  'searchRequestMethod': _$RequestMethodEnumMap[instance.searchRequestMethod]!,
  'searchRequestBody': instance.searchRequestBody,
  'searchRequestHeaders': instance.searchRequestHeaders,
  'fullSearchUrl': instance.fullSearchUrl,
  'timeout': instance.timeout,
  'searchSelector': instance.searchSelector,
  'itemImgSelector': instance.itemImgSelector,
  'itemImgFromSrc': instance.itemImgFromSrc,
  'itemTitleSelector': instance.itemTitleSelector,
  'itemIdSelector': instance.itemIdSelector,
  'itemGenreSelector': instance.itemGenreSelector,
  'detailUrl': instance.detailUrl,
  'detailRequestMethod': _$RequestMethodEnumMap[instance.detailRequestMethod]!,
  'detailRequestBody': instance.detailRequestBody,
  'detailRequestHeaders': instance.detailRequestHeaders,
  'fullDetailUrl': instance.fullDetailUrl,
  'lineSelector': instance.lineSelector,
  'episodeSelector': instance.episodeSelector,
  'playerUrl': instance.playerUrl,
  'playerRequestMethod': _$RequestMethodEnumMap[instance.playerRequestMethod]!,
  'playerRequestBody': instance.playerRequestBody,
  'playerRequestHeaders': instance.playerRequestHeaders,
  'fullPlayerUrl': instance.fullPlayerUrl,
  'playerVideoSelector': instance.playerVideoSelector,
  'videoElementAttribute': instance.videoElementAttribute,
  'embedVideoSelector': instance.embedVideoSelector,
  'waitForMediaElement': instance.waitForMediaElement,
  'videoUrlSubsChar': instance.videoUrlSubsChar,
  'updateAt': instance.updateAt.toIso8601String(),
  'isEnabled': instance.isEnabled,
  'isLocal': instance.isLocal,
};

const _$RequestMethodEnumMap = {
  RequestMethod.get: 'get',
  RequestMethod.post: 'post',
  RequestMethod.put: 'put',
  RequestMethod.delete: 'delete',
  RequestMethod.head: 'head',
  RequestMethod.options: 'options',
};
