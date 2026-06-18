import 'package:dio/dio.dart';
import 'package:holo/entity/anime_info.dart';
import 'package:holo/entity/daily_broadcast.dart';
import 'package:holo/entity/episode_item.dart';
import 'package:holo/entity/image.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/related_work.dart';
import 'package:holo/env/env.dart';
import 'package:holo/service/meta_service.dart';
import 'package:holo/util/datetime_util.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/logger_util.dart';
import 'package:logger/logger.dart';

/// Bangumi 元数据服务类
/// 实现了 MetaService 接口，提供 Bangumi 网站的元数据服务
class Bangumi implements MetaService {
  String languageCode;
  static final String defaultMetaServerUrl = "https://api.bgm.tv";
  static final String metaServerUrl = Env.metaServerUrl ?? defaultMetaServerUrl;
  final Logger _logger = LoggerUtil.logger;
  @override
  /// 获取服务名称
  String get name => "Bangumi";

  @override
  /// 获取网站基础地址,https://api.bgm.tv
  String get baseUrl => metaServerUrl;

  @override
  /// 获取网站logo地址
  String get logoUrl => "https://bangumi.tv/img/logo_riff.png";

  /// Dio 实例
  Dio? _dio;

  /// 初始化 Dio 实例
  Bangumi({this.languageCode = 'zh'}) {
    _dio = HttpUtil.createDio();
  }

  /// 获取日历详细信息
  /// 返回 subjectId 和播出时间的映射
  Future<Map<String, DateTime>> _fetchCalender() async {
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
        result[subjectId] = dateTime.toLocal();
      }
      return result;
    } catch (e) {
      _logger.e('fetchCalenderDetail error: ${e.toString()}');
      return {};
    }
  }

  @override
  Future<List<DailyBroadcast>> fetchDailyBroadcast(
    void Function(Exception ex) exceptionHandler,
  ) async {
    try {
      // 获取日历详细信息
      var calenderDetail = await _fetchCalender();
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
            var images = itemData["images"] as Map<String, dynamic>?;
            var airDate = itemData['air_date'] as String?;
            return AnimeInfo(
              id: itemData["id"],
              title: title,
              images: Image.fromJson(images ?? {}),
              latestEpisode: currentEpisode,

              airDateTime: airDate != null ? DateTime.parse(airDate) : null,
            );
          }).toList();
          return DailyBroadcast(
            dayOfWeek: dayData['weekday']['id'] as int,
            items: dailyItems,
          );
        }).toList();

        // 补充播出时间信息
        if (calenderDetail.isNotEmpty) {
          for (var item in dailyBroadcasts) {
            for (var subject in item.items) {
              if (calenderDetail.containsKey(subject.id.toString())) {
                var time = calenderDetail[subject.id.toString()];
                subject.airDateTime = subject.airDateTime?.copyWith(
                  hour: time?.hour,
                  minute: time?.minute,
                );
              }
            }
          }
        }
        return dailyBroadcasts;
      }
      return [];
    } catch (e) {
      _logger.e('fetchDailyBroadcast error: ${e.toString()}');
      exceptionHandler(e as Exception);
      return [];
    }
  }

  @override
  Future<List<Person>> fetchCharacters(
    int subjectId,
    void Function(Exception) exceptionHandler,
  ) async {
    try {
      // 发起获取角色信息的请求
      final response = await _dio!.get(
        "$baseUrl/v0/subjects/$subjectId/characters",
      );
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        return data.map((e) => Person.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      exceptionHandler(e as Exception);
      return [];
    }
  }

  @override
  Future<List<Person>> fetchStaffs(
    int subjectId,
    void Function(Exception) exceptionHandler,
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
      exceptionHandler(e as Exception);
      return [];
    }
  }

  @override
  Future<List<AnimeInfo>> fetchRecommend({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
    String sort = "date",
    required void Function(Exception ex) exceptionHandler,
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
          return AnimeInfo(
            id: subject["id"] as int,
            title: title,
            images: Image.fromJson(subject["images"] as Map<String, dynamic>),
            summary: subject["summary"] as String,
            rating: double.tryParse(subject["rating"]["score"].toString()),
            ratingCount: subject["rating"]?["total"] as int,
            episodes: subject["eps"] as int,
            airDateTime: subject["date"] != null
                ? DateTime.tryParse(subject["date"] as String)
                : null,
            genres:
                (subject["meta_tags"] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
            type: subject["platform"] as String,
            latestEpisode:
                checkUpdateAt(subject["date"] as String?) ??
                subject["eps"] as int,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      exceptionHandler(e as Exception);
      return [];
    }
  }

  @override
  Future<List<AnimeInfo>> fetchSearch(
    String keyword,
    void Function(Exception ex) exceptionHandler,
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
        queryParameters: {"limit": 100},
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
          return AnimeInfo(
            id: subject["id"] as int,
            title: title,
            images: Image.fromJson(subject["images"] as Map<String, dynamic>),
            rating: double.tryParse(subject["rating"]["score"].toString()),
            airDateTime: subject["date"] != null
                ? DateTime.tryParse(subject["date"] as String)
                : null,
            summary: subject["summary"] as String,
            ratingCount: subject["rating"]?["total"] as int,
            episodes: subject["eps"] as int,
            genres:
                (subject["meta_tags"] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
            type: subject["platform"] as String,
            latestEpisode:
                checkUpdateAt(subject["date"] as String?) ??
                subject["eps"] as int,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      _logger.e(e.toString());
      exceptionHandler(e as Exception);
      return [];
    }
  }

  @override
  Future<List<RelatedWork>> fetchRelatedWorks(
    int subjectId,
    void Function(Exception ex) exceptionHandler,
  ) async {
    try {
      // 发起获取关联媒体的请求
      final response = await _dio!.get(
        "$baseUrl/v0/subjects/$subjectId/subjects",
      );
      if (response.data != null) {
        var data = response.data as List<dynamic>;
        return data.map((e) => RelatedWork.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      exceptionHandler(e as Exception);
      return [];
    }
  }

  @override
  Future<AnimeInfo?> fetchAnimeInfoById(
    int subjectId,
    void Function(Exception ex) exceptionHandler,
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
        return AnimeInfo(
          id: data["id"] as int,
          title: title,
          images: Image.fromJson(data["images"] as Map<String, dynamic>),
          summary: data["summary"] as String,
          rating: double.tryParse(data["rating"]["score"].toString()),
          ratingCount: data["rating"]?["total"] as int,
          episodes: data["eps"] as int,
          genres:
              (data["meta_tags"] as List?)?.map((e) => e as String).toList() ??
              [],
          airDateTime: data["date"] != null
              ? DateTime.tryParse(data["date"] as String)
              : null,
          type: data["platform"] as String,
          latestEpisode:
              checkUpdateAt(data["date"] as String?) ?? data["eps"] as int,
        );
      }
      return null;
    } catch (e) {
      exceptionHandler(e as Exception);
      return null;
    }
  }

  @override
  Future<List<EpisodeInfo>> fetchEpisodeInfos(
    int subjectId,
    void Function(Exception ex) exceptionHandler,
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
          return EpisodeInfo(
            id: episode["id"] as int,
            title: title,
            number: episode["ep"] as int,
            description: episode["desc"] as String,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      exceptionHandler(e as Exception);
      return [];
    }
  }
}
