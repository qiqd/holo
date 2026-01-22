import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:holo/entity/calendar.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/episode.dart' hide EpisodeData;
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/service/meta_service.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/webview_util.dart';

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

  Future<Map<String, DateTime>> _fetchCalenderDetail() async {
    try {
      final rs = await HttpUtil.createDio().get(
        'https://bgmlist.com/api/v1/bangumi/onair',
      );
      var items = (rs.data as Map<String, dynamic>)['items'] as List;
      var result = <String, DateTime>{};
      for (var item in items) {
        var subject = item as Map<String, dynamic>;
        var broadcast = (subject['broadcast'] ?? '') as String;
        var sites = subject['sites'] as List;
        if (sites.isEmpty || broadcast.isEmpty) {
          continue;
        }
        var subjectId =
            (sites.firstWhere(
                      (site) => site['site'] == 'bangumi',
                      orElse: () => {'id': '12345678'},
                    )['id'] ??
                    '')
                as String;
        if (subjectId.isEmpty) {
          continue;
        }
        var time = broadcast.substring(
          broadcast.indexOf('/') + 1,
          broadcast.lastIndexOf('/'),
        );
        var dateTime = DateTime.parse(time);
        dateTime = dateTime.add(const Duration(hours: 8));
        result[subjectId] = dateTime;
        log('subjectId: $subjectId, time: $time, dateTime: $dateTime');
      }
      return result;
    } catch (e) {
      log('fetchCalenderDetail error: ${e.toString()}');
      return {};
    }
  }

  @override
  Future<List<Calendar>> fetchCalendarSync(
    void Function(Exception) exception,
  ) async {
    try {
      var calenderDetail = await _fetchCalenderDetail();
      final response = await _dio!.get("$baseUrl/calendar");
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        var result = data.map((e) => Calendar.fromJson(e)).toList();
        if (calenderDetail.isNotEmpty) {
          for (var item in result) {
            for (var subject in item.items!) {
              if (calenderDetail.containsKey(subject.id.toString())) {
                var time = calenderDetail[subject.id.toString()];
                subject.airDate = '${time!.hour}:${time.minute}';
              }
            }
          }
        }
        return result;
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
