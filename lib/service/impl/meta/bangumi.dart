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

/// Bangumi 元数据服务类
/// 实现了 MetaService 接口，提供 Bangumi 网站的元数据服务
class Bangumi implements MetaService {
  @override
  /// 获取服务名称
  String get name => "Bangumi";

  @override
  /// 获取网站基础地址
  String get baseUrl => "https://api.bgm.tv";

  @override
  /// 获取网站logo地址
  String get logoUrl => "https://bangumi.tv/img/logo_riff.png";

  /// Dio 实例
  static Dio? _dio;

  /// 初始化 Dio 实例
  static Future<void> initDio() async {
    _dio = await HttpUtil.createDioWithUserAgent();
  }

  /// 获取日历详细信息
  /// 返回 subjectId 和播出时间的映射
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
      }
      return result;
    } catch (e) {
      log('fetchCalenderDetail error: ${e.toString()}');
      return {};
    }
  }

  @override
  /// 获取日历信息
  /// [exception] 异常处理器
  /// 返回日历列表
  Future<List<Calendar>> fetchCalendar(
    void Function(Exception) exception,
  ) async {
    try {
      // 获取日历详细信息
      var calenderDetail = await _fetchCalenderDetail();
      // 发起获取日历的请求
      final response = await _dio!.get("$baseUrl/calendar");
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        var result = data.map((e) => Calendar.fromJson(e)).toList();
        // 补充播出时间信息
        if (calenderDetail.isNotEmpty) {
          for (var item in result) {
            for (var subject in item.items!) {
              if (calenderDetail.containsKey(subject.id.toString())) {
                var time = calenderDetail[subject.id.toString()];
                subject.airDate =
                    '${subject.airDate ?? ''}/${time!.hour}:${time.minute}';
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
  /// 获取角色信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回角色列表
  Future<List<Character>> fetchCharacter(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      // 发起获取角色信息的请求
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
  /// 获取人物信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回人物列表
  Future<List<Person>> fetchPerson(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      // 发起获取人物信息的请求
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
  /// 获取推荐媒体
  /// [page] 页码
  /// [size] 每页数量
  /// [year] 年份
  /// [month] 月份
  /// [sort] 排序方式
  /// [exception] 异常处理器
  /// 返回推荐结果
  Future<Subject?> fetchRecommend({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
    String sort = "date",
    void Function(Exception)? exception,
  }) async {
    // 构建请求参数
    var param = Map.from({
      "type": 2,
      "cat": 1,
      "sort": sort,
      "limit": size,
      "month": month,
      "offset": (page - 1) * size,
      "year": year,
    });
    // 移除空值参数
    param.removeWhere((key, value) => value == null);
    try {
      // 发起获取推荐的请求
      final response = await _dio!.get(
        "$baseUrl/v0/subjects",
        queryParameters: Map.from(param),
      );
      if (response.data != null) {
        return Subject.fromJson(response.data);
      }
      return null;
    } catch (e) {
      exception?.call(e as Exception);
      return null;
    }
  }

  @override
  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [exception] 异常处理器
  /// 返回搜索结果
  Future<Subject?> fetchSearch(
    String keyword,
    void Function(dynamic) exception,
  ) async {
    try {
      // 发起搜索请求
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
  /// 获取媒体关联信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回关联媒体列表
  Future<List<SubjectRelation>> fetchSubjectRelation(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      // 发起获取关联媒体的请求
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
  /// 获取媒体详情
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回媒体详情
  Future<Data?> fetchSubjectSync(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      // 发起获取媒体详情的请求
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
  /// 获取剧集信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回剧集信息
  Future<Episode?> fethcEpisode(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      // 发起获取剧集信息的请求
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
