import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:holo/entity/calendar.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/episode.dart' hide EpisodeData;
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/service/meta_service.dart';
import 'package:holo/util/http_util.dart';

class Bangumi implements MetaService {
  @override
  String get name => "Bangumi";

  @override
  String get baseUrl => "https://api.bgm.tv";

  @override
  String get logoUrl => "https://bangumi.tv/img/logo_riff.png";
  static Dio? _dio;
  static Future<void> initDio() async {
    _dio = await HttpUtil.createDioWithUserAgent();
  }

  @override
  Future<List<Calendar>> fetchCalendarSync(
    void Function(Exception) exception,
  ) async {
    try {
      final response = await _dio!.get("$baseUrl/calendar");
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        return data.map((e) => Calendar.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      exception(e as Exception);
      return [];
    }
  }

  @override
  Future<List<Character>> fetchCharacterSync(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      final response = await _dio!.get(
        "$baseUrl/v0/subjects/$subjectId/characters",
      );
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        return data.map((e) => Character.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      exception(e as Exception);
      return [];
    }
  }

  @override
  Future<List<Person>> fetchPersonSync(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      final response = await _dio!.get(
        "$baseUrl/v0/subjects/$subjectId/persons",
      );
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        return data.map((e) => Person.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      exception(e as Exception);
      return [];
    }
  }

  @override
  Future<Subject?> fetchRecommendSync(
    int page,
    int size,
    void Function(Exception) exception,
  ) async {
    var param = Map.from({
      "type": 2,
      "cat": 1,
      "sort": "date",
      "limit": size,
      "offset": (page - 1) * size,
      "year": DateTime.now().year,
    });
    try {
      final response = await _dio!.get(
        "$baseUrl/v0/subjects",
        queryParameters: Map.from(param),
      );
      if (response.data != null) {
        return Subject.fromJson(response.data);
      }
      return null;
    } catch (e) {
      exception(e as Exception);
      return null;
    }
  }

  @override
  Future<Subject?> fetchSearchSync(
    String keyword,
    void Function(dynamic) exception,
  ) async {
    try {
      final response = await _dio!.post(
        "$baseUrl/v0/search/subjects",
        data: {
          "keyword": keyword,
          "sort": "match",
          "filter": {
            "type": [2],
          },
        },
      );
      if (response.data != null) {
        return Subject.fromJson(response.data);
      }
      return null;
    } catch (e) {
      log(e.toString());
      exception(e);
      return null;
    }
  }

  @override
  Future<List<SubjectRelation>> fetchSubjectRelationSync(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      final response = await _dio!.get(
        "$baseUrl/v0/subjects/$subjectId/subjects",
      );
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        return data.map((e) => SubjectRelation.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      exception(e as Exception);
      return [];
    }
  }

  @override
  Future<Data?> fetchSubjectSync(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      final response = await _dio!.get("$baseUrl/v0/subjects/$subjectId");
      if (response.data != null) {
        return Data.fromJson(response.data);
      }
      return null;
    } catch (e) {
      exception(e as Exception);
      return null;
    }
  }

  @override
  Future<Episode?> fethcEpisodeSync(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      final response = await _dio!.get(
        "$baseUrl/v0/episodes",
        queryParameters: {"subject_id": subjectId},
      );
      if (response.data != null) {
        return Episode.fromJson(response.data);
      }
      return null;
    } catch (e) {
      exception(e as Exception);
      return null;
    }
  }
}
