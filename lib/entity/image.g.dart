// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageAdapter extends TypeAdapter<Image> {
  @override
  final typeId = 7;

  @override
  Image read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Image(
      small: fields[0] as String?,
      grid: fields[1] as String?,
      large: fields[2] as String?,
      medium: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Image obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.small)
      ..writeByte(1)
      ..write(obj.grid)
      ..writeByte(2)
      ..write(obj.large)
      ..writeByte(3)
      ..write(obj.medium);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Image _$ImageFromJson(Map<String, dynamic> json) => Image(
  small: json['small'] as String?,
  grid: json['grid'] as String?,
  large: json['large'] as String?,
  medium: json['medium'] as String?,
);

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
  'small': instance.small,
  'grid': instance.grid,
  'large': instance.large,
  'medium': instance.medium,
};
