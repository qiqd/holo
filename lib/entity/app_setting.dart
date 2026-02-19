import 'package:json_annotation/json_annotation.dart';
part 'app_setting.g.dart';

@JsonSerializable(explicitToJson: true)
class AppSetting {
  /// 弹幕设置
  DanmakuSetting danmakuSetting;

  ///使用系统颜色，只在Android 12+ 以上版本生效s
  bool useSystemColor;

  /// 主题模式
  /// 0: 系统主题
  /// 1: 浅色主题
  /// 2: 深色主题
  int themeMode;

  /// 主颜色
  int colorSeed;

  AppSetting({
    this.danmakuSetting = const DanmakuSetting(),
    this.useSystemColor = false,
    this.themeMode = 0,
    this.colorSeed = 0xffd08b57,
  });
  AppSetting copyWith({
    DanmakuSetting? danmakuSetting,
    bool? useSystemColor,
    int? themeMode,
    int? colorSeed,
  }) {
    return AppSetting(
      danmakuSetting: danmakuSetting ?? this.danmakuSetting,
      useSystemColor: useSystemColor ?? this.useSystemColor,
      themeMode: themeMode ?? this.themeMode,
      colorSeed: colorSeed ?? this.colorSeed,
    );
  }

  Map<String, dynamic> toJson() => _$AppSettingToJson(this);
  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(json);
}

@JsonSerializable(explicitToJson: true)
class DanmakuSetting {
  final double opacity;
  final double area;
  final double fontSize;
  final bool hideTop;
  final bool hideScroll;
  final bool hideBottom;
  final bool massiveMode;
  final int danmakuOffset;

  /// 过滤词，英文逗号分隔
  final String filterWords;
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

  Map<String, dynamic> toJson() => _$DanmakuSettingToJson(this);
  factory DanmakuSetting.fromJson(Map<String, dynamic> json) =>
      _$DanmakuSettingFromJson(json);
}
