import 'package:holo/entity/media.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/common_source_service.dart';
import 'package:holo/util/flutter_inappwebview_util.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/logger_util.dart';

/// Sorane 动画源服务
/// 通过 REST API 获取数据
class Sorane extends CommonSourceService {
  @override
  int delay = 9999;

  @override
  String getBaseUrl() {
    return "https://api.sorani.cc";
  }

  @override
  String getLogoUrl() {
    return "https://www.sorani.net/favicon.ico";
  }

  @override
  String getName() {
    return "Sorane";
  }

  @override
  FlutterInappwebviewUtil? get webviewUtil => null;

  Sorane()
    : super(
        rule: Rule(
          playerRequestHeaders: {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36 Edg/156.0.0.0",
            "Origin": "https://www.sorani.net",
          },
        ),
      );

  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// [size] 每页数量
  /// [exceptionHandler] 异常处理器
  @override
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    void Function(String) exceptionHandler, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final searchUrl =
        "${getBaseUrl()}/sorani-cms/api/video?page=$page&size=$size&keyword=$keyword&enabled=true&sortMode=relevance_popular&sortDesc=true";
    try {
      final dio = HttpUtil.createDio();
      dio.options.headers["Origin"] = "https://www.sorani.net";
      final response = await dio.get(searchUrl);

      if (response.statusCode == 200) {
        var decode = response.data as Map<String, dynamic>;
        var records = decode["data"]["records"] as List<dynamic>;

        return records.map((item) {
          var id = "/video/${item["id"]}";
          var title = item["title"] as String?;
          var cover = item["cover"] as String?;
          var type = item["tags"] as String?;
          return Media(id: id, title: title, coverUrl: cover, type: type);
        }).toList();
      }
      return [];
    } catch (e) {
      LoggerUtil.logger.e("Sorane fetchSearch error: $e");
      exceptionHandler(e.toString());
      return [];
    }
  }

  /// 解析媒体详情信息
  /// [mediaId] 媒体ID
  /// [exceptionHandler] 异常处理器
  @override
  Future<Detail?> fetchDetail(
    String mediaId,
    void Function(String) exceptionHandler,
  ) async {
    try {
      var id = mediaId.replaceAll("/video/", "");
      final response = await HttpUtil.createDio().get(
        "${getBaseUrl()}/sorani-cms/api/video/$id",
      );

      if (response.statusCode == 200) {
        var decode = response.data as Map<String, dynamic>;
        var episodes = decode["data"]["episodes"] as List<dynamic>? ?? [];

        var episodeList = episodes.map((ep) {
          return "/episode/${ep["episodeId"]}";
        }).toList();

        return Detail(lines: [Line(episodes: episodeList)]);
      }
      return null;
    } catch (e) {
      LoggerUtil.logger.e("Sorane fetchDetail error: $e");
      exceptionHandler(e.toString());
      return null;
    }
  }

  /// 解析播放地址
  /// [episodeId] 剧集ID
  /// [exceptionHandler] 异常处理器
  @override
  Future<String?> fetchVideoUrl(
    String episodeId,
    void Function(String) exceptionHandler,
  ) async {
    try {
      var id = episodeId.replaceAll("/episode/", "");
      final dio = HttpUtil.createDio();
      dio.options.headers["Referer"] = "https://www.sorani.net/";
      final response = await dio.get(
        "${getBaseUrl()}/sorani-cms/api/video/episode/$id/play?lineCode=anime_jp_m3u8",
      );

      if (response.statusCode == 200) {
        var decode = response.data as Map<String, dynamic>;
        return decode["data"]["playUrl"] as String?;
      }
      return null;
    } catch (e) {
      LoggerUtil.logger.e("Sorane fetchVideoUrl error: $e");
      exceptionHandler(e.toString());
      return null;
    }
  }
}
