// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectItemAdapter extends TypeAdapter<SubjectItem> {
  @override
  final typeId = 4;

  @override
  SubjectItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectItem(
      id: (fields[0] as num).toInt(),
      title: fields[1] as String,
      images: fields[2] as Image,
      summary: fields[3] as String,
      ratingCount: (fields[4] as num).toInt(),
      totalEpisodes: (fields[5] as num).toInt(),
      metaTags: (fields[6] as List).cast<String>(),
      currentEpisode: (fields[7] as num?)?.toInt(),
      airTime: fields[8] as String?,
      airDate: fields[9] as String?,
      rating: (fields[10] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SubjectItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.images)
      ..writeByte(3)
      ..write(obj.summary)
      ..writeByte(4)
      ..write(obj.ratingCount)
      ..writeByte(5)
      ..write(obj.totalEpisodes)
      ..writeByte(6)
      ..write(obj.metaTags)
      ..writeByte(7)
      ..write(obj.currentEpisode)
      ..writeByte(8)
      ..write(obj.airTime)
      ..writeByte(9)
      ..write(obj.airDate)
      ..writeByte(10)
      ..write(obj.rating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectItem _$SubjectItemFromJson(Map<String, dynamic> json) => SubjectItem(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  images: Image.fromJson(json['images'] as Map<String, dynamic>),
  summary: json['summary'] as String,
  ratingCount: (json['ratingCount'] as num).toInt(),
  totalEpisodes: (json['totalEpisodes'] as num).toInt(),
  metaTags: (json['metaTags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  currentEpisode: (json['currentEpisode'] as num?)?.toInt(),
  airTime: json['airTime'] as String?,
  airDate: json['airDate'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SubjectItemToJson(SubjectItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images': instance.images,
      'summary': instance.summary,
      'ratingCount': instance.ratingCount,
      'totalEpisodes': instance.totalEpisodes,
      'metaTags': instance.metaTags,
      'currentEpisode': instance.currentEpisode,
      'airTime': instance.airTime,
      'airDate': instance.airDate,
      'rating': instance.rating,
    };
