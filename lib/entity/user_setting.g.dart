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
    );
  }

  @override
  void write(BinaryWriter writer, UserSetting obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.useLastSource);
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
