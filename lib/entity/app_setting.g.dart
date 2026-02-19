// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSetting _$AppSettingFromJson(Map<String, dynamic> json) => AppSetting(
  danmakuSetting: json['danmakuSetting'] == null
      ? const DanmakuSetting()
      : DanmakuSetting.fromJson(json['danmakuSetting'] as Map<String, dynamic>),
  useSystemColor: json['useSystemColor'] as bool? ?? false,
  themeMode: (json['themeMode'] as num?)?.toInt() ?? 0,
  colorSeed: (json['primaryColor'] as num?)?.toInt() ?? 0xffd08b57,
);

Map<String, dynamic> _$AppSettingToJson(AppSetting instance) =>
    <String, dynamic>{
      'danmakuSetting': instance.danmakuSetting.toJson(),
      'useSystemColor': instance.useSystemColor,
      'themeMode': instance.themeMode,
      'primaryColor': instance.colorSeed,
    };

DanmakuSetting _$DanmakuSettingFromJson(Map<String, dynamic> json) =>
    DanmakuSetting(
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      area: (json['area'] as num?)?.toDouble() ?? 1.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      hideTop: json['hideTop'] as bool? ?? false,
      hideScroll: json['hideScroll'] as bool? ?? false,
      hideBottom: json['hideBottom'] as bool? ?? false,
      massiveMode: json['massiveMode'] as bool? ?? false,
      filterWords: json['filterWords'] as String? ?? '',
      danmakuOffset: json['danmakuOffset'] as int? ?? 0,
    );

Map<String, dynamic> _$DanmakuSettingToJson(DanmakuSetting instance) =>
    <String, dynamic>{
      'opacity': instance.opacity,
      'area': instance.area,
      'fontSize': instance.fontSize,
      'hideTop': instance.hideTop,
      'hideScroll': instance.hideScroll,
      'hideBottom': instance.hideBottom,
      'massiveMode': instance.massiveMode,
      'filterWords': instance.filterWords,
      'danmakuOffset': instance.danmakuOffset,
    };
