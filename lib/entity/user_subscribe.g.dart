// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_subscribe.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSubscribeAdapter extends TypeAdapter<UserSubscribe> {
  @override
  final typeId = 0;

  @override
  UserSubscribe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSubscribe(
      id: (fields[0] as num).toInt(),
      email: fields[1] as String,
      title: fields[2] as String,
      imgUrl: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isSync: fields[5] as bool,
      viewingStatus: (fields[6] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSubscribe obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.imgUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isSync)
      ..writeByte(6)
      ..write(obj.viewingStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscribeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
