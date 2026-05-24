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
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> map) {
    return UserSetting(
      email: map['email'],
      opacity: map['opacity'] ?? 1.0,
      area: map['area'] ?? 1.0,
      fontSize: map['fontSize'] ?? 16,
      hideTop: map['hideTop'] ?? false,
      hideScroll: map['hideScroll'] ?? false,
      hideBottom: map['hideBottom'] ?? false,
      massiveMode: map['massiveMode'] ?? false,
      filterWords: map['filterWords'] ?? '',
      useSystemColor: map['useSystemColor'] ?? false,
      themeMode: map['themeMode'] ?? 0,
      colorSeed: map['colorSeed'] ?? 0xffd08b57,
      autoUpdate: map['autoUpdate'] ?? true,
      useLastSource: map['useLastSource'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'opacity': opacity,
      'area': area,
      'fontSize': fontSize,
      'hideTop': hideTop,
      'hideScroll': hideScroll,
      'hideBottom': hideBottom,
      'massiveMode': massiveMode,
      'filterWords': filterWords,
      'useSystemColor': useSystemColor,
      'themeMode': themeMode,
      'colorSeed': colorSeed,
      'autoUpdate': autoUpdate,
      'useLastSource': useLastSource,
    };
  }
}
