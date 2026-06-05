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
    <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Image();
  }

  @override
  void write(BinaryWriter writer, Image obj) {
    writer.writeByte(0);
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
  large: json['large'] as String?,
  medium: json['medium'] as String?,
  grid: json['grid'] as String?,
);

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
  'small': instance.small,
  'large': instance.large,
  'medium': instance.medium,
  'grid': instance.grid,
};
