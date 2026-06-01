// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnimeInfoAdapter extends TypeAdapter<AnimeInfo> {
  @override
  final typeId = 11;

  @override
  AnimeInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnimeInfo(
      id: (fields[0] as num).toInt(),
      title: fields[1] as String,
      images: fields[2] as Image,
      episodes: (fields[6] as num?)?.toInt(),
      latestEpisode: (fields[10] as num?)?.toInt(),
      type: fields[9] as String?,
      summary: fields[3] as String?,
      genres: fields[7] == null ? const [] : (fields[7] as List).cast<String>(),
      ratingCount: (fields[4] as num?)?.toInt(),
      rating: (fields[5] as num?)?.toDouble(),
      airDateTime: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AnimeInfo obj) {
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
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.episodes)
      ..writeByte(7)
      ..write(obj.genres)
      ..writeByte(8)
      ..write(obj.airDateTime)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.latestEpisode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnimeInfo _$AnimeInfoFromJson(Map<String, dynamic> json) => AnimeInfo(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  images: Image.fromJson(json['images'] as Map<String, dynamic>),
  episodes: (json['episodes'] as num?)?.toInt(),
  latestEpisode: (json['latestEpisode'] as num?)?.toInt(),
  type: json['type'] as String?,
  summary: json['summary'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  ratingCount: (json['ratingCount'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
  airDateTime: json['airDateTime'] == null
      ? null
      : DateTime.parse(json['airDateTime'] as String),
);

Map<String, dynamic> _$AnimeInfoToJson(AnimeInfo instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'images': instance.images,
  'summary': instance.summary,
  'ratingCount': instance.ratingCount,
  'rating': instance.rating,
  'episodes': instance.episodes,
  'genres': instance.genres,
  'airDateTime': instance.airDateTime?.toIso8601String(),
  'type': instance.type,
  'latestEpisode': instance.latestEpisode,
};
