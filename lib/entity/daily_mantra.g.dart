// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_mantra.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyMantraAdapter extends TypeAdapter<DailyMantra> {
  @override
  final typeId = 12;

  @override
  DailyMantra read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMantra(
      mantra: fields[0] as String,
      type: fields[1] as String,
      date: fields[2] as DateTime,
      from: fields[4] as String,
      who: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMantra obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.mantra)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.who)
      ..writeByte(4)
      ..write(obj.from);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMantraAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyMantra _$DailyMantraFromJson(Map<String, dynamic> json) => DailyMantra(
  mantra: json['mantra'] as String,
  type: json['type'] as String,
  date: DateTime.parse(json['date'] as String),
  from: json['from'] as String,
  who: json['who'] as String?,
);

Map<String, dynamic> _$DailyMantraToJson(DailyMantra instance) =>
    <String, dynamic>{
      'mantra': instance.mantra,
      'type': instance.type,
      'date': instance.date.toIso8601String(),
      'who': instance.who,
      'from': instance.from,
    };
