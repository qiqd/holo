import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/daily_broadcast.dart';
import 'package:holo/entity/episode_item.dart';
import 'package:holo/entity/image.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/service/meta_service.dart';
import 'package:holo/util/datetime_util.dart';
import 'package:holo/util/http_util.dart';
import 'package:logger/logger.dart';

/// Bangumi 元数据服务类
/// 实现了 MetaService 接口，提供 Bangumi 网站的元数据服务
class Bangumi implements MetaService {
  static String languageCode = 'zh';
  final Logger _logger = Logger();
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
  static Future<void> init({String code = 'zh'}) async {
    languageCode = code;
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
  Future<List<DailyBroadcast>> fetchDailyBroadcast(
    void Function(String) exception,
  ) async {
    try {
      // 获取日历详细信息
      var calenderDetail = await _fetchCalenderDetail();
      // 发起获取日历的请求
      final response = await _dio!.get("$baseUrl/calendar");
      if (response.data != null) {
        var data = response.data as List;
        var dailyBroadcasts = data.map((day) {
          var dayData = day as Map<String, dynamic>;
          var items = dayData['items'] as List;
          var dailyItems = items.map((item) {
            var itemData = item as Map<String, dynamic>;
            var title = switch (languageCode) {
              'zh' =>
                (itemData["name_cn"] as String).isNotEmpty
                    ? itemData["name_cn"] as String
                    : itemData["name"] ?? '',
              _ => itemData["name"] ?? '',
            };
            var currentEpisode = checkUpdateAt(itemData['air_date']);
            return SubjectItem(
              id: itemData["id"],
              title: title,
              images: Image.fromJson(
                itemData["images"] as Map<String, dynamic>,
              ),
              currentEpisode: currentEpisode,
              summary: "",
              ratingCount: 0,
              rating: 0,
              totalEpisodes: 0,
              metaTags: [],
            );
          }).toList();
          return DailyBroadcast(
            weekOfDay: dayData['weekday']["id"] as int,
            items: dailyItems,
          );
        }).toList();

        // 补充播出时间信息
        if (calenderDetail.isNotEmpty) {
          for (var item in dailyBroadcasts) {
            for (var subject in item.items) {
              if (calenderDetail.containsKey(subject.id.toString())) {
                var time = calenderDetail[subject.id.toString()];
                subject.airTime = time.toString();
              }
            }
          }
        }
        return dailyBroadcasts;
      }
      return [];
    } catch (e) {
      _logger.e('fetchDailyBroadcast error: ${e.toString()}');
      exception(e.toString());
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
  Future<List<SubjectItem>> fetchRecommend({
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
        var data = (response.data as Map<String, dynamic>)["data"] as List;
        return data.map((item) {
          var subject = item as Map<String, dynamic>;
          var title = switch (languageCode) {
            'zh' =>
              (subject["name_cn"] as String).isNotEmpty
                  ? subject["name_cn"] as String
                  : subject["name"] ?? '',
            _ => subject["name"] ?? '',
          };
          return SubjectItem(
            id: subject["id"] as int,
            title: title,
            images: Image.fromJson(subject["images"] as Map<String, dynamic>),
            summary: subject["summary"] as String,
            rating: double.tryParse(subject["rating"]["score"].toString()),
            ratingCount: subject["rating"]?["total"] as int,
            totalEpisodes: subject["eps"] as int,
            airDate: subject["date"] as String?,
            metaTags:
                (subject["meta_tags"] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      exception?.call(e as Exception);
      return [];
    }
  }

  @override
  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [exception] 异常处理器
  /// 返回搜索结果
  Future<List<SubjectItem>> fetchSearch(
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
        var data = (response.data as Map<String, dynamic>)["data"] as List;
        return data.map((item) {
          var subject = item as Map<String, dynamic>;
          var title = switch (languageCode) {
            'zh' =>
              (subject["name_cn"] as String).isNotEmpty
                  ? subject["name_cn"] as String
                  : subject["name"] ?? '',
            _ => subject["name"] ?? '',
          };
          return SubjectItem(
            id: subject["id"] as int,
            title: title,
            images: Image.fromJson(subject["images"] as Map<String, dynamic>),
            rating: double.tryParse(subject["rating"]["score"].toString()),
            airDate: subject["date"] as String?,
            summary: subject["summary"] as String,
            ratingCount: subject["rating"]?["total"] as int,
            totalEpisodes: subject["eps"] as int,
            metaTags:
                (subject["meta_tags"] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      log(e.toString());
      exception(e);
      return [];
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
  Future<SubjectItem?> fetchSubjectById(
    int subjectId,
    void Function(Exception) exception,
  ) async {
    try {
      // 发起获取媒体详情的请求
      final response = await _dio!.get("$baseUrl/v0/subjects/$subjectId");
      if (response.data != null) {
        var data = response.data as Map<String, dynamic>;
        var title = switch (languageCode) {
          'zh' =>
            (data["name_cn"] as String).isNotEmpty
                ? data["name_cn"] as String
                : data["name"] ?? '',
          _ => data["name"] ?? '',
        };
        return SubjectItem(
          id: data["id"] as int,
          title: title,
          images: Image.fromJson(data["images"] as Map<String, dynamic>),
          summary: data["summary"] as String,
          rating: double.tryParse(data["rating"]["score"].toString()),
          ratingCount: data["rating"]?["total"] as int,
          totalEpisodes: data["eps"] as int,
          metaTags:
              (data["meta_tags"] as List?)?.map((e) => e as String).toList() ??
              [],
          airDate: data["date"] as String?,
          currentEpisode: checkUpdateAt(data["date"] as String?),
        );
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
  Future<List<Episode>> fetchEpisode(
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
        var data = (response.data as Map<String, dynamic>)["data"] as List;
        return data.map((item) {
          var episode = item as Map<String, dynamic>;
          var title = switch (languageCode) {
            'zh' =>
              (episode["name"] as String).isNotEmpty
                  ? episode["name_cn"] as String
                  : episode[" name"] ?? '',
            _ => episode["name"] ?? '',
          };
          return Episode(
            id: episode["id"] as int,
            title: title,
            number: episode["ep"] as int,
            description: episode["desc"] as String?,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      exception(e as Exception);
      return [];
    }
  }
}
