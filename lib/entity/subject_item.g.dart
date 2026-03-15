// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_item.dart';

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
