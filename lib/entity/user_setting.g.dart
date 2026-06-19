// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_setting.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingAdapter extends TypeAdapter<UserSetting> {
  @override
  final typeId = 3;

  @override
  UserSetting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSetting(
      email: fields[0] as String,
      opacity: (fields[1] as num).toDouble(),
      area: (fields[2] as num).toDouble(),
      fontSize: (fields[3] as num).toDouble(),
      hideTop: fields[4] as bool,
      hideScroll: fields[5] as bool,
      hideBottom: fields[6] as bool,
      massiveMode: fields[7] as bool,
      filterWords: fields[8] as String,
      useSystemColor: fields[9] as bool,
      themeMode: (fields[10] as num).toInt(),
      colorSeed: (fields[11] as num).toInt(),
      autoUpdate: fields[12] == null ? true : fields[12] as bool,
      useLastSource: fields[13] == null ? true : fields[13] as bool,
      dataSyncInterval: fields[14] == null ? 10 : (fields[14] as num).toInt(),
      playerSafeInset: fields[15] == null ? 40 : (fields[15] as num).toInt(),
      danmakuOffset: fields[16] == null ? 0 : (fields[16] as num).toInt(),
      enableSplash: fields[17] == null ? true : fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSetting obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.opacity)
      ..writeByte(2)
      ..write(obj.area)
      ..writeByte(3)
      ..write(obj.fontSize)
      ..writeByte(4)
      ..write(obj.hideTop)
      ..writeByte(5)
      ..write(obj.hideScroll)
      ..writeByte(6)
      ..write(obj.hideBottom)
      ..writeByte(7)
      ..write(obj.massiveMode)
      ..writeByte(8)
      ..write(obj.filterWords)
      ..writeByte(9)
      ..write(obj.useSystemColor)
      ..writeByte(10)
      ..write(obj.themeMode)
      ..writeByte(11)
      ..write(obj.colorSeed)
      ..writeByte(12)
      ..write(obj.autoUpdate)
      ..writeByte(13)
      ..write(obj.useLastSource)
      ..writeByte(14)
      ..write(obj.dataSyncInterval)
      ..writeByte(15)
      ..write(obj.playerSafeInset)
      ..writeByte(16)
      ..write(obj.danmakuOffset)
      ..writeByte(17)
      ..write(obj.enableSplash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSetting _$UserSettingFromJson(Map<String, dynamic> json) => UserSetting(
  email: json['email'] as String,
  opacity: (json['opacity'] as num).toDouble(),
  area: (json['area'] as num).toDouble(),
  fontSize: (json['fontSize'] as num).toDouble(),
  hideTop: json['hideTop'] as bool,
  hideScroll: json['hideScroll'] as bool,
  hideBottom: json['hideBottom'] as bool,
  massiveMode: json['massiveMode'] as bool,
  filterWords: json['filterWords'] as String,
  useSystemColor: json['useSystemColor'] as bool,
  themeMode: (json['themeMode'] as num).toInt(),
  colorSeed: (json['colorSeed'] as num).toInt(),
  autoUpdate: json['autoUpdate'] as bool? ?? true,
  useLastSource: json['useLastSource'] as bool? ?? true,
  dataSyncInterval: (json['dataSyncInterval'] as num?)?.toInt() ?? 10,
  playerSafeInset: (json['playerSafeInset'] as num?)?.toInt() ?? 40,
  danmakuOffset: (json['danmakuOffset'] as num?)?.toInt() ?? 0,
  enableSplash: json['enableSplash'] as bool? ?? true,
);

Map<String, dynamic> _$UserSettingToJson(UserSetting instance) =>
    <String, dynamic>{
      'email': instance.email,
      'opacity': instance.opacity,
      'area': instance.area,
      'fontSize': instance.fontSize,
      'hideTop': instance.hideTop,
      'hideScroll': instance.hideScroll,
      'hideBottom': instance.hideBottom,
      'massiveMode': instance.massiveMode,
      'filterWords': instance.filterWords,
      'useSystemColor': instance.useSystemColor,
      'themeMode': instance.themeMode,
      'colorSeed': instance.colorSeed,
      'autoUpdate': instance.autoUpdate,
      'useLastSource': instance.useLastSource,
      'dataSyncInterval': instance.dataSyncInterval,
      'playerSafeInset': instance.playerSafeInset,
      'danmakuOffset': instance.danmakuOffset,
      'enableSplash': instance.enableSplash,
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
      danmakuOffset: (json['danmakuOffset'] as num?)?.toInt() ?? 0,
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
      'danmakuOffset': instance.danmakuOffset,
      'filterWords': instance.filterWords,
    };
