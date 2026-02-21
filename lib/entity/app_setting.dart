import 'package:json_annotation/json_annotation.dart';
part 'app_setting.g.dart';

/// 应用设置类
/// 包含应用的全局设置信息
@JsonSerializable(explicitToJson: true)
class AppSetting {
  /// 弹幕设置
  DanmakuSetting danmakuSetting;

  /// 使用系统颜色，只在Android 12+ 以上版本生效
  bool useSystemColor;

  /// 主题模式
  /// 0: 系统主题
  /// 1: 浅色主题
  /// 2: 深色主题
  int themeMode;

  /// 主颜色
  int colorSeed;

  /// 构造函数
  /// [danmakuSetting] 弹幕设置，默认为默认弹幕设置
  /// [useSystemColor] 是否使用系统颜色，默认为false
  /// [themeMode] 主题模式，默认为0（系统主题）
  /// [colorSeed] 主颜色，默认为0xffd08b57
  AppSetting({
    this.danmakuSetting = const DanmakuSetting(),
    this.useSystemColor = false,
    this.themeMode = 0,
    this.colorSeed = 0xffd08b57,
  });

  /// 复制方法，用于创建一个新的AppSetting实例并修改指定字段
  /// [danmakuSetting] 弹幕设置
  /// [useSystemColor] 是否使用系统颜色
  /// [themeMode] 主题模式
  /// [colorSeed] 主颜色
  /// 返回新的AppSetting实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$AppSettingToJson(this);

  /// 从JSON格式创建AppSetting实例
  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(json);
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
