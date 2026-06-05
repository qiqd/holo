import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_setting.g.dart';

@immutable
@HiveType(typeId: 3)
@JsonSerializable(explicitToJson: true)
class UserSetting {
  @HiveField(0)
  final String email;
  @HiveField(1)
  final double opacity;
  @HiveField(2)
  final double area;
  @HiveField(3)
  final double fontSize;
  @HiveField(4)
  final bool hideTop;
  @HiveField(5)
  final bool hideScroll;
  @HiveField(6)
  final bool hideBottom;
  @HiveField(7)
  final bool massiveMode;
  @HiveField(8)
  final String filterWords;
  @HiveField(9)
  final bool useSystemColor;
  @HiveField(10)
  final int themeMode;
  @HiveField(11)
  final int colorSeed;
  @HiveField(12)
  final bool autoUpdate;
  @HiveField(13)
  final bool useLastSource;
  @HiveField(14)
  final int dataSyncInterval;
  @HiveField(15)
  final int playerSafeInset;
  @HiveField(16)
  final int danmakuOffset;
  const UserSetting({
    required this.email,
    required this.opacity,
    required this.area,
    required this.fontSize,
    required this.hideTop,
    required this.hideScroll,
    required this.hideBottom,
    required this.massiveMode,
    required this.filterWords,
    required this.useSystemColor,
    required this.themeMode,
    required this.colorSeed,
    this.autoUpdate = true,
    this.useLastSource = true,
    this.dataSyncInterval = 10,
    this.playerSafeInset = 40,
    this.danmakuOffset = 0,
  });

  static UserSetting createDefaultUserSetting({required String email}) {
    return UserSetting(
      email: email,
      opacity: 1.0,
      area: 1.0,
      fontSize: 16,
      hideTop: false,
      hideScroll: false,
      hideBottom: false,
      massiveMode: false,
      filterWords: '',
      useSystemColor: false,
      themeMode: 0,
      colorSeed: 0xffd08b57,
      autoUpdate: true,
      useLastSource: true,
    );
  }

  DanmakuSetting getDanmakuSetting() {
    return DanmakuSetting(
      opacity: opacity,
      area: area,
      fontSize: fontSize,
      hideTop: hideTop,
      hideScroll: hideScroll,
      hideBottom: hideBottom,
      massiveMode: massiveMode,
      filterWords: filterWords,
    );
  }

  UserSetting copyWith({
    String? email,
    double? opacity,
    double? area,
    double? fontSize,
    bool? hideTop,
    bool? hideScroll,
    bool? hideBottom,
    bool? massiveMode,
    int? danmakuOffset,
    String? filterWords,
    bool? useSystemColor,
    int? themeMode,
    int? colorSeed,
    bool? autoUpdate,
    bool? useLastSource,
    int? dataSyncInterval,
    int? playerSafeInset,
  }) {
    return UserSetting(
      email: email ?? this.email,
      opacity: opacity ?? this.opacity,
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      hideTop: hideTop ?? this.hideTop,
      hideScroll: hideScroll ?? this.hideScroll,
      hideBottom: hideBottom ?? this.hideBottom,
      massiveMode: massiveMode ?? this.massiveMode,
      filterWords: filterWords ?? this.filterWords,
      useSystemColor: useSystemColor ?? this.useSystemColor,
      themeMode: themeMode ?? this.themeMode,
      colorSeed: colorSeed ?? this.colorSeed,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      useLastSource: useLastSource ?? this.useLastSource,
      dataSyncInterval: dataSyncInterval ?? this.dataSyncInterval,
      playerSafeInset: playerSafeInset ?? this.playerSafeInset,
      danmakuOffset: danmakuOffset ?? this.danmakuOffset,
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> map) {
    return _$UserSettingFromJson(map);
  }
  Map<String, dynamic> toJson() {
    return _$UserSettingToJson(this);
  }
}

/// 弹幕设置类
/// 包含弹幕的显示设置
@JsonSerializable(explicitToJson: true)
class DanmakuSetting {
  /// 弹幕透明度
  final double opacity;

  /// 弹幕显示区域
  final double area;

  /// 弹幕字体大小
  final double fontSize;

  /// 是否隐藏顶部弹幕
  final bool hideTop;

  /// 是否隐藏滚动弹幕
  final bool hideScroll;

  /// 是否隐藏底部弹幕
  final bool hideBottom;

  /// 是否启用密集模式
  final bool massiveMode;

  /// 弹幕偏移量
  final int danmakuOffset;

  /// 过滤词，英文逗号分隔
  final String filterWords;

  /// 构造函数
  /// [opacity] 弹幕透明度，默认为1.0
  /// [area] 弹幕显示区域，默认为1.0
  /// [fontSize] 弹幕字体大小，默认为16
  /// [hideTop] 是否隐藏顶部弹幕，默认为false
  /// [hideScroll] 是否隐藏滚动弹幕，默认为false
  /// [hideBottom] 是否隐藏底部弹幕，默认为false
  /// [massiveMode] 是否启用密集模式，默认为false
  /// [filterWords] 过滤词，默认为空字符串
  /// [danmakuOffset] 弹幕偏移量，默认为0
  const DanmakuSetting({
    this.opacity = 1.0,
    this.area = 1.0,
    this.fontSize = 16,
    this.hideTop = false,
    this.hideScroll = false,
    this.hideBottom = false,
    this.massiveMode = false,
    this.filterWords = '',
    this.danmakuOffset = 0,
  });

  /// 复制方法，用于创建一个新的DanmakuSetting实例并修改指定字段
  /// [opacity] 弹幕透明度
  /// [area] 弹幕显示区域
  /// [fontSize] 弹幕字体大小
  /// [hideTop] 是否隐藏顶部弹幕
  /// [hideScroll] 是否隐藏滚动弹幕
  /// [hideBottom] 是否隐藏底部弹幕
  /// [massiveMode] 是否启用密集模式
  /// [filterWords] 过滤词
  /// [danmakuOffset] 弹幕偏移量
  /// 返回新的DanmakuSetting实例
  DanmakuSetting copyWith({
    double? opacity,
    double? area,
    double? fontSize,
    bool? hideTop,
    bool? hideScroll,
    bool? hideBottom,
    bool? massiveMode,
    String? filterWords,
    int? danmakuOffset,
  }) {
    return DanmakuSetting(
      opacity: opacity ?? this.opacity,
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      hideTop: hideTop ?? this.hideTop,
      hideScroll: hideScroll ?? this.hideScroll,
      hideBottom: hideBottom ?? this.hideBottom,
      massiveMode: massiveMode ?? this.massiveMode,
      filterWords: filterWords ?? this.filterWords,
      danmakuOffset: danmakuOffset ?? this.danmakuOffset,
    );
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$DanmakuSettingToJson(this);

  /// 从JSON格式创建DanmakuSetting实例
  factory DanmakuSetting.fromJson(Map<String, dynamic> json) =>
      _$DanmakuSettingFromJson(json);
}
