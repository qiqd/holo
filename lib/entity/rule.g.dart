// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RuleAdapter extends TypeAdapter<Rule> {
  @override
  final typeId = 5;

  @override
  Rule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rule(
      name: fields[0] == null ? '' : fields[0] as String,
      logoUrl: fields[2] == null ? '' : fields[2] as String,
      useWebView: fields[3] == null ? false : fields[3] as bool,
      searchUrl: fields[5] == null ? '' : fields[5] as String,
      detailUrl: fields[17] == null ? '' : fields[17] as String,
      playerUrl: fields[25] == null ? '' : fields[25] as String,
      searchSelector: fields[11] == null ? '' : fields[11] as String,
      lineSelector: fields[22] == null ? '' : fields[22] as String,
      episodeSelector: fields[23] == null ? '' : fields[23] as String,
      playerVideoSelector: fields[30] == null ? '' : fields[30] as String,
      itemImgSelector: fields[12] == null ? '' : fields[12] as String,
      itemTitleSelector: fields[14] == null ? '' : fields[14] as String,
      itemIdSelector: fields[15] == null ? '' : fields[15] as String,
      baseUrl: fields[1] == null ? '' : fields[1] as String,
      fullSearchUrl: fields[9] == null ? false : fields[9] as bool,
      fullPlayerUrl: fields[29] == null ? false : fields[29] as bool,
      fullDetailUrl: fields[21] == null ? false : fields[21] as bool,
      itemImgFromSrc: fields[13] == null ? true : fields[13] as bool,
      waitForTargetElement: fields[33] == null ? true : fields[33] as bool,
      episodeReverse: fields[24] == null ? false : fields[24] as bool,
      searchRequestHeaders: fields[8] == null
          ? defaultUserAgent
          : (fields[8] as Map).cast<String, String>(),
      detailRequestHeaders: fields[20] == null
          ? defaultUserAgent
          : (fields[20] as Map).cast<String, String>(),
      playerRequestHeaders: fields[28] == null
          ? defaultUserAgent
          : (fields[28] as Map).cast<String, String>(),
      searchRequestBody: fields[7] == null
          ? const {}
          : (fields[7] as Map).cast<String, String>(),
      detailRequestBody: fields[19] == null
          ? const {}
          : (fields[19] as Map).cast<String, String>(),
      playerRequestBody: fields[27] == null
          ? const {}
          : (fields[27] as Map).cast<String, String>(),
      videoElementAttribute: fields[31] == null ? '' : fields[31] as String,
      version: fields[4] == null ? '1.0' : fields[4] as String,
      isEnabled: fields[36] == null ? true : fields[36] as bool,
      timeout: fields[10] == null ? 5 : (fields[10] as num).toInt(),
      isLocal: fields[37] == null ? true : fields[37] as bool,
      searchRequestMethod: fields[6] == null
          ? RequestMethod.get
          : fields[6] as RequestMethod,
      detailRequestMethod: fields[18] == null
          ? RequestMethod.get
          : fields[18] as RequestMethod,
      playerRequestMethod: fields[26] == null
          ? RequestMethod.get
          : fields[26] as RequestMethod,
      embedVideoSelector: fields[32] == null ? '' : fields[32] as String,
      itemGenreSelector: fields[16] == null ? '' : fields[16] as String?,
      videoUrlSubsChar: fields[34] == null ? '' : fields[34] as String,
      email: fields[38] == null ? '' : fields[38] as String,
      isValid: fields[39] == null ? true : fields[39] as bool,
    )..updateAt = fields[35] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Rule obj) {
    writer
      ..writeByte(40)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.baseUrl)
      ..writeByte(2)
      ..write(obj.logoUrl)
      ..writeByte(3)
      ..write(obj.useWebView)
      ..writeByte(4)
      ..write(obj.version)
      ..writeByte(5)
      ..write(obj.searchUrl)
      ..writeByte(6)
      ..write(obj.searchRequestMethod)
      ..writeByte(7)
      ..write(obj.searchRequestBody)
      ..writeByte(8)
      ..write(obj.searchRequestHeaders)
      ..writeByte(9)
      ..write(obj.fullSearchUrl)
      ..writeByte(10)
      ..write(obj.timeout)
      ..writeByte(11)
      ..write(obj.searchSelector)
      ..writeByte(12)
      ..write(obj.itemImgSelector)
      ..writeByte(13)
      ..write(obj.itemImgFromSrc)
      ..writeByte(14)
      ..write(obj.itemTitleSelector)
      ..writeByte(15)
      ..write(obj.itemIdSelector)
      ..writeByte(16)
      ..write(obj.itemGenreSelector)
      ..writeByte(17)
      ..write(obj.detailUrl)
      ..writeByte(18)
      ..write(obj.detailRequestMethod)
      ..writeByte(19)
      ..write(obj.detailRequestBody)
      ..writeByte(20)
      ..write(obj.detailRequestHeaders)
      ..writeByte(21)
      ..write(obj.fullDetailUrl)
      ..writeByte(22)
      ..write(obj.lineSelector)
      ..writeByte(23)
      ..write(obj.episodeSelector)
      ..writeByte(24)
      ..write(obj.episodeReverse)
      ..writeByte(25)
      ..write(obj.playerUrl)
      ..writeByte(26)
      ..write(obj.playerRequestMethod)
      ..writeByte(27)
      ..write(obj.playerRequestBody)
      ..writeByte(28)
      ..write(obj.playerRequestHeaders)
      ..writeByte(29)
      ..write(obj.fullPlayerUrl)
      ..writeByte(30)
      ..write(obj.playerVideoSelector)
      ..writeByte(31)
      ..write(obj.videoElementAttribute)
      ..writeByte(32)
      ..write(obj.embedVideoSelector)
      ..writeByte(33)
      ..write(obj.waitForTargetElement)
      ..writeByte(34)
      ..write(obj.videoUrlSubsChar)
      ..writeByte(35)
      ..write(obj.updateAt)
      ..writeByte(36)
      ..write(obj.isEnabled)
      ..writeByte(37)
      ..write(obj.isLocal)
      ..writeByte(38)
      ..write(obj.email)
      ..writeByte(39)
      ..write(obj.isValid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RequestMethodAdapter extends TypeAdapter<RequestMethod> {
  @override
  final typeId = 6;

  @override
  RequestMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RequestMethod.get;
      case 1:
        return RequestMethod.post;
      default:
        return RequestMethod.get;
    }
  }

  @override
  void write(BinaryWriter writer, RequestMethod obj) {
    switch (obj) {
      case RequestMethod.get:
        writer.writeByte(0);
      case RequestMethod.post:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rule _$RuleFromJson(Map<String, dynamic> json) => Rule(
  name: json['name'] as String? ?? '',
  logoUrl: json['logoUrl'] as String? ?? '',
  useWebView: json['useWebView'] as bool? ?? false,
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
  waitForTargetElement: json['waitForTargetElement'] as bool? ?? true,
  episodeReverse: json['episodeReverse'] as bool? ?? false,
  searchRequestHeaders:
      (json['searchRequestHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      defaultUserAgent,
  detailRequestHeaders:
      (json['detailRequestHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      defaultUserAgent,
  playerRequestHeaders:
      (json['playerRequestHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      defaultUserAgent,
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
  videoElementAttribute: json['videoElementAttribute'] as String? ?? '',
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
  embedVideoSelector: json['embedVideoSelector'] as String? ?? '',
  itemGenreSelector: json['itemGenreSelector'] as String? ?? '',
  videoUrlSubsChar: json['videoUrlSubsChar'] as String? ?? '',
  email: json['email'] as String? ?? '',
  isValid: json['isValid'] as bool? ?? true,
)..updateAt = DateTime.parse(json['updateAt'] as String);

Map<String, dynamic> _$RuleToJson(Rule instance) => <String, dynamic>{
  'name': instance.name,
  'baseUrl': instance.baseUrl,
  'logoUrl': instance.logoUrl,
  'useWebView': instance.useWebView,
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
  'episodeReverse': instance.episodeReverse,
  'playerUrl': instance.playerUrl,
  'playerRequestMethod': _$RequestMethodEnumMap[instance.playerRequestMethod]!,
  'playerRequestBody': instance.playerRequestBody,
  'playerRequestHeaders': instance.playerRequestHeaders,
  'fullPlayerUrl': instance.fullPlayerUrl,
  'playerVideoSelector': instance.playerVideoSelector,
  'videoElementAttribute': instance.videoElementAttribute,
  'embedVideoSelector': instance.embedVideoSelector,
  'waitForTargetElement': instance.waitForTargetElement,
  'videoUrlSubsChar': instance.videoUrlSubsChar,
  'updateAt': instance.updateAt.toIso8601String(),
  'isEnabled': instance.isEnabled,
  'isLocal': instance.isLocal,
  'email': instance.email,
  'isValid': instance.isValid,
};

const _$RequestMethodEnumMap = {
  RequestMethod.get: 'get',
  RequestMethod.post: 'post',
};
