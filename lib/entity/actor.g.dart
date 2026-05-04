// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActorAdapter extends TypeAdapter<Actor> {
  @override
  final typeId = 10;

  @override
  Actor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Actor(
      images: fields[0] as Image?,
      name: fields[1] as String?,
      shortSummary: fields[2] as String?,
      career: (fields[3] as List?)?.cast<String>(),
      id: (fields[4] as num?)?.toInt(),
      type: (fields[5] as num?)?.toInt(),
      locked: fields[6] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Actor obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.images)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.shortSummary)
      ..writeByte(3)
      ..write(obj.career)
      ..writeByte(4)
      ..write(obj.id)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.locked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Actor _$ActorFromJson(Map<String, dynamic> json) => Actor(
  images: json['images'] == null
      ? null
      : Image.fromJson(json['images'] as Map<String, dynamic>),
  name: json['name'] as String?,
  shortSummary: json['shortSummary'] as String?,
  career: (json['career'] as List<dynamic>?)?.map((e) => e as String).toList(),
  id: (json['id'] as num?)?.toInt(),
  type: (json['type'] as num?)?.toInt(),
  locked: json['locked'] as bool?,
);

Map<String, dynamic> _$ActorToJson(Actor instance) => <String, dynamic>{
  'images': instance.images?.toJson(),
  'name': instance.name,
  'shortSummary': instance.shortSummary,
  'career': instance.career,
  'id': instance.id,
  'type': instance.type,
  'locked': instance.locked,
};
