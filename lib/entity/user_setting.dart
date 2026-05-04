import 'package:holo/entity/app_setting.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'user_setting.g.dart';

@HiveType(typeId: 3)
@immutable
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
  final int danmakuOffset;
  @HiveField(9)
  final String filterWords;
  @HiveField(10)
  final bool useSystemColor;
  @HiveField(11)
  final int themeMode;
  @HiveField(12)
  final int colorSeed;
  @HiveField(13)
  final bool autoUpdate;
  const UserSetting({
    required this.email,
    required this.opacity,
    required this.area,
    required this.fontSize,
    required this.hideTop,
    required this.hideScroll,
    required this.hideBottom,
    required this.massiveMode,
    required this.danmakuOffset,
    required this.filterWords,
    required this.useSystemColor,
    required this.themeMode,
    required this.colorSeed,
    this.autoUpdate = true,
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
      danmakuOffset: 0,
      filterWords: '',
      useSystemColor: false,
      themeMode: 0,
      colorSeed: 0xffd08b57,
      autoUpdate: true,
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
      danmakuOffset: danmakuOffset,
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
      danmakuOffset: danmakuOffset ?? this.danmakuOffset,
      filterWords: filterWords ?? this.filterWords,
      useSystemColor: useSystemColor ?? this.useSystemColor,
      themeMode: themeMode ?? this.themeMode,
      colorSeed: colorSeed ?? this.colorSeed,
      autoUpdate: autoUpdate ?? this.autoUpdate,
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> map) {
    return UserSetting(
      email: map['email'],
      opacity: map['opacity'],
      area: map['area'],
      fontSize: map['fontSize'],
      hideTop: map['hideTop'] == 1,
      hideScroll: map['hideScroll'] == 1,
      hideBottom: map['hideBottom'] == 1,
      massiveMode: map['massiveMode'] == 1,
      danmakuOffset: map['danmakuOffset'],
      filterWords: map['filterWords'],
      useSystemColor: map['useSystemColor'] == 1,
      themeMode: map['themeMode'],
      colorSeed: map['colorSeed'],
      autoUpdate: map['autoUpdate'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'opacity': opacity,
      'area': area,
      'fontSize': fontSize,
      'hideTop': hideTop ? 1 : 0,
      'hideScroll': hideScroll ? 1 : 0,
      'hideBottom': hideBottom ? 1 : 0,
      'massiveMode': massiveMode ? 1 : 0,
      'danmakuOffset': danmakuOffset,
      'filterWords': filterWords,
      'useSystemColor': useSystemColor ? 1 : 0,
      'themeMode': themeMode,
      'colorSeed': colorSeed,
      'autoUpdate': autoUpdate ? 1 : 0,
    };
  }
}
