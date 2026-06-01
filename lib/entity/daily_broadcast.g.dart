// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_broadcast.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyBroadcastAdapter extends TypeAdapter<DailyBroadcast> {
  @override
  final typeId = 8;

  @override
  DailyBroadcast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyBroadcast(
      dayOfWeek: (fields[0] as num).toInt(),
      items: (fields[1] as List).cast<AnimeInfo>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyBroadcast obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyBroadcastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyBroadcast _$DailyBroadcastFromJson(Map<String, dynamic> json) =>
    DailyBroadcast(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => AnimeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DailyBroadcastToJson(DailyBroadcast instance) =>
    <String, dynamic>{'dayOfWeek': instance.dayOfWeek, 'items': instance.items};
