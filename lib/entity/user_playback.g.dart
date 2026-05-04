// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_playback.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPlaybackAdapter extends TypeAdapter<UserPlayback> {
  @override
  final typeId = 1;

  @override
  UserPlayback read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPlayback(
      id: (fields[0] as num).toInt(),
      email: fields[1] as String,
      title: fields[2] as String,
      imgUrl: fields[3] as String,
      lastPlaybackAt: fields[4] as DateTime,
      createdAt: fields[5] as DateTime,
      position: (fields[6] as num).toInt(),
      episodeIndex: (fields[7] as num).toInt(),
      lineIndex: (fields[8] as num).toInt(),
      isSync: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPlayback obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.imgUrl)
      ..writeByte(4)
      ..write(obj.lastPlaybackAt)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.position)
      ..writeByte(7)
      ..write(obj.episodeIndex)
      ..writeByte(8)
      ..write(obj.lineIndex)
      ..writeByte(9)
      ..write(obj.isSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPlaybackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
