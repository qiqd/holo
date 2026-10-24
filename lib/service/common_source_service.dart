import 'dart:convert';

import 'package:holo/entity/media.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/flutter_inappwebview_util.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/logger_util.dart';
import 'package:html/parser.dart';
import 'package:logger/web.dart';

/// 通用动画源服务类
/// 根据规则配置构建动画源服务
class CommonSourceService extends SourceService {
  /// 规则配置对象
  final Rule rule;

  /// 视频URL匹配正则表达式
  final pattern = RegExp(
    r'https?://[^?&\s]*?\.(?:m3u8|mp4)(?:\?[^&\s]*)?(?=&|\s|$)',
    caseSensitive: false,
  );

  /// 占位符匹配正则表达式
  final RegExp reg = RegExp(r'\{[^}]*\}');

  /// WebView工具类实例
  final FlutterInappwebviewUtil webviewUtil = FlutterInappwebviewUtil();

  final Logger _logger = LoggerUtil.logger;

  /// 构造函数
  /// [rule] 规则配置对象
  CommonSourceService({required this.rule}) {
    if (rule.useWebView) {
      webviewUtil.fetchHtmlOrJson(rule.baseUrl);
    }
  }

  /// 工厂构造函数
  /// [rule] 规则配置对象
  factory CommonSourceService.build(Rule rule) =>
      CommonSourceService(rule: rule);

  /// 获取网站基础地址
  @override
  String getBaseUrl() {
    return rule.baseUrl;
  }

  /// 获取网站logo地址
  @override
  String getLogoUrl() {
    return rule.logoUrl;
  }

  /// 获取服务名称
  @override
  String getName() {
    return rule.name;
  }

  /// 服务延迟时间
  @override
  int delay = 9999;

  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// [size] 每页数量
  /// [exceptionHandler] 异常处理器
  /// [timeout] 超时时间
  /// 返回媒体列表
  @override
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    Function(String) exceptionHandler, {
    timeout = const Duration(seconds: 60),
  }) async {
    try {
      // 构建搜索URL
      var searchUrl = rule.baseUrl + rule.searchUrl.replaceAll(reg, keyword);
      // 获取HTML内容
      final htmlStr = switch (rule.useWebView) {
        true => await webviewUtil.fetchHtmlOrJson(
          // 纯JS规则时加载首页执行脚本，否则加载搜索页
          rule.isPureJs
              ? rule.baseUrl
              : (keyword.contains('http') ? keyword : searchUrl),
          requestMethod: rule.searchRequestMethod,
          requestBody: rule.searchRequestBody.map(
            (key, value) => MapEntry(key, value.replaceAll(reg, keyword)),
          ),
          timeout: Duration(seconds: rule.timeout),
          headers: rule.searchRequestHeaders,
          waitingForTargetElement: rule.waitForTargetElement,
          targetElementSelector: rule.searchSelector,
          onError: exceptionHandler,
          injectedScript: rule.isPureJs
              ? rule.decodedSearchScript?.replaceAll('{keyword}', keyword)
              : rule.decodedSearchScript,
        ),
        false =>
          (await HttpUtil.createDio().get(
                keyword.contains('http') ? keyword : searchUrl,
              )).data
              as String,
      };

      // 如果配置了搜索JS脚本，优先使用JS脚本返回的JSON数据
      // 纯JS规则时强制使用JS脚本
      if (rule.searchScript != null && rule.searchScript!.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(htmlStr);
          return jsonList.map((e) {
            final map = e as Map<String, dynamic>;
            var imgUrl = map['coverUrl']?.toString() ?? '';
            imgUrl = imgUrl.contains('http') ? imgUrl : rule.baseUrl + imgUrl;
            imgUrl = imgUrl.contains("https") ? imgUrl : ('https://$imgUrl');
            var id = map['id']?.toString() ?? '';
            id = id.contains('http') ? id : rule.baseUrl + id;
            return Media(
              id: id,
              title: map['title']?.toString() ?? '',
              coverUrl: imgUrl,
              type: map['type']?.toString(),
            );
          }).toList();
        } catch (e) {
          _logger.e('JS脚本返回的JSON解析失败: $e');
          exceptionHandler('JS脚本返回的JSON解析失败: $e');
          return [];
        }
      }

      // 纯JS规则时，不解析CSS选择器
      if (rule.isPureJs) {
        return [];
      }

      // 解析HTML文档
      var doc = parse(htmlStr);
      // 图片属性列表
      var imgAttrs = ['data-original', 'data-src'];
      // 提取媒体信息
      return doc.querySelectorAll(rule.searchSelector).map((e) {
        var imgUrl = '';
        // 从不同属性中获取图片URL
        if (rule.itemImgFromSrc) {
          imgUrl =
              e.querySelector(rule.itemImgSelector)?.attributes['src'] ?? '';
        } else {
          for (var attr in imgAttrs) {
            var temp =
                e.querySelector(rule.itemImgSelector)?.attributes[attr] ?? '';
            if (temp.isNotEmpty) {
              imgUrl = temp;
              break;
            }
          }
        }
        // 补全图片URL
        imgUrl = imgUrl.contains('http') ? imgUrl : rule.baseUrl + imgUrl;
        imgUrl = imgUrl.contains("https") ? imgUrl : ('https://$imgUrl');
        //先尝试在子元素中查找，如果找不到，再尝试从当前元素自身获取：
        var idElement = e.querySelector(rule.itemIdSelector);
        var mediaId =
            idElement?.attributes['href'] ?? e.attributes['href'] ?? '';
        // 构建媒体对象
        return Media(
          id: mediaId,
          title: e.querySelector(rule.itemTitleSelector)?.text ?? '',
          coverUrl: imgUrl,
          type:
              (rule.itemGenreSelector != null &&
                  rule.itemGenreSelector!.isNotEmpty)
              ? e.querySelector(rule.itemGenreSelector!)?.text
              : null,
        );
      }).toList();
    } catch (e) {
      exceptionHandler(e.toString());
      return [];
    }
  }

  /// 解析媒体详情信息
  /// [mediaId] 媒体ID
  /// [exceptionHandler] 异常处理器
  /// 返回详情信息对象
  @override
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(String) exceptionHandler,
  ) async {
    try {
      // 构建详情页URL
      var detailUrl = rule.baseUrl + rule.detailUrl.replaceAll(reg, mediaId);
      // 获取HTML内容
      final htmlStr = switch (rule.useWebView) {
        true => await webviewUtil.fetchHtmlOrJson(
          // 纯JS规则时加载首页执行脚本，否则加载详情页
          rule.isPureJs
              ? rule.baseUrl
              : (mediaId.contains('http') ? mediaId : detailUrl),
          requestMethod: rule.detailRequestMethod,
          timeout: Duration(seconds: rule.timeout),
          headers: rule.detailRequestHeaders,
          requestBody: rule.detailRequestBody.map(
            (key, value) => MapEntry(key, value.replaceAll(reg, mediaId)),
          ),
          waitingForTargetElement: rule.waitForTargetElement,
          targetElementSelector: rule.lineSelector,
          onError: exceptionHandler,
          injectedScript: rule.isPureJs
              ? rule.decodedDetailScript?.replaceAll('{mediaId}', mediaId)
              : rule.decodedDetailScript,
        ),
        false =>
          (await HttpUtil.createDio().get(
                mediaId.contains('http') ? mediaId : detailUrl,
              )).data
              as String,
      };

      // 如果配置了详情JS脚本，优先使用JS脚本返回的JSON数据
      // 纯JS规则时强制使用JS脚本
      if (rule.detailScript != null && rule.detailScript!.isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(htmlStr);
          final List<dynamic> linesJson =
              jsonMap['lines'] as List<dynamic>? ?? [];
          final lines = linesJson.map((line) {
            final List<dynamic> episodesJson =
                (line as Map<String, dynamic>)['episodes'] as List<dynamic>? ??
                [];
            var episodes = episodesJson.map((e) => e.toString()).toList();
            if (rule.episodeReverse) {
              episodes = episodes.reversed.toList();
            }
            return Line(episodes: episodes);
          }).toList();
          return Detail(lines: lines);
        } catch (e) {
          _logger.e('JS脚本返回的JSON解析失败: $e');
          exceptionHandler('JS脚本返回的JSON解析失败: $e');
          return null;
        }
      }

      // 纯JS规则时，不解析CSS选择器
      if (rule.isPureJs) {
        return null;
      }

      // 解析HTML文档
      var doc = parse(htmlStr);
      // 提取剧集信息
      var lines = doc.querySelectorAll(rule.lineSelector).map((line) {
        final episode = line.querySelectorAll(rule.episodeSelector);
        var episodes = episode.map((e) {
          return e.attributes['href'] ?? '';
        }).toList();
        if (rule.episodeReverse) {
          episodes = episodes.reversed.toList();
        }
        return Line(episodes: episodes);
      }).toList();
      return Detail(lines: lines);
    } catch (e) {
      exceptionHandler(e.toString());
    }
    return null;
  }

  @override
  /// 解析播放地址
  /// [episodeId] 剧集ID
  /// [exceptionHandler] 异常处理器
  /// 返回播放地址字符串
  Future<String?> fetchVideoUrl(
    String episodeId,
    Function(String) exceptionHandler,
  ) async {
    try {
      // 构建播放页URL
      var viewUrl = rule.baseUrl + rule.playerUrl.replaceAll(reg, episodeId);
      // 获取HTML内容
      final htmlStr = switch (rule.useWebView) {
        true => await webviewUtil.fetchHtmlOrJson(
          // 纯JS规则时加载首页执行脚本，否则加载播放页
          rule.isPureJs
              ? rule.baseUrl
              : (episodeId.contains('http') ? episodeId : viewUrl),
          timeout: Duration(seconds: rule.timeout),
          requestMethod: rule.playerRequestMethod,
          requestBody: rule.playerRequestBody.map(
            (key, value) => MapEntry(key, value.replaceAll(reg, episodeId)),
          ),
          isPlayerPage: true,
          headers: rule.playerRequestHeaders,
          waitingForTargetElement: rule.waitForTargetElement,
          targetElementSelector: rule.playerVideoSelector,
          onError: exceptionHandler,
          injectedScript: rule.isPureJs
              ? rule.decodedPlayerScript?.replaceAll('{episodeId}', episodeId)
              : rule.decodedPlayerScript,
        ),
        false =>
          (await HttpUtil.createDio().get(
                episodeId.contains('http') ? episodeId : viewUrl,
              )).data
              as String,
      };

      // 如果配置了播放JS脚本，优先使用JS脚本返回的JSON数据
      // 纯JS规则时强制使用JS脚本
      if (rule.playerScript != null && rule.playerScript!.isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(htmlStr);
          var videoUrl = jsonMap['videoUrl']?.toString() ?? '';
          // 补全URL
          if (videoUrl.isNotEmpty && !videoUrl.contains('http')) {
            videoUrl = rule.baseUrl + videoUrl;
          }
          _logger.d("JS脚本返回的videoUrl:$videoUrl");
          return videoUrl.isNotEmpty ? videoUrl : null;
        } catch (e) {
          _logger.e('JS脚本返回的JSON解析失败: $e');
          exceptionHandler('JS脚本返回的JSON解析失败: $e');
          return null;
        }
      }

      // 解析HTML文档
      var doc = parse(htmlStr);
      // 处理嵌入式视频
      if (rule.embedVideoSelector.isNotEmpty) {
        var embedSelectors = rule.embedVideoSelector.split(',');
        for (var selector in embedSelectors) {
          var tempUrl = doc.querySelector(selector)?.attributes['src'] ?? '';
          tempUrl = tempUrl.contains('http')
              ? tempUrl
              : (rule.baseUrl + tempUrl);
          var tempHtmlStr = switch (rule.useWebView) {
            true => await webviewUtil.fetchHtmlOrJson(
              tempUrl,
              isPlayerPage: true,
              headers: rule.playerRequestHeaders,

              waitingForTargetElement: rule.waitForTargetElement,
              targetElementSelector: selector,
              timeout: Duration(seconds: rule.timeout),
            ),
            false => (await HttpUtil.createDio().get(tempUrl)).data as String,
          };
          doc = parse(tempHtmlStr);
          _logger.d("embed selector:$selector, tempUrl:$tempUrl");
        }
      }
      // 从videoElement中获取视频URL
      var videoElement = doc.querySelector(rule.playerVideoSelector);
      var videoAttributes = videoElement?.attributes ?? {};
      var videoUrl = '';
      // 如果规则中指定了视频元素属性，直接从属性中获取URL
      if (rule.videoElementAttribute.isNotEmpty) {
        videoUrl =
            doc
                .querySelector(rule.playerVideoSelector)
                ?.attributes[rule.videoElementAttribute] ??
            '';
        videoUrl = (videoUrl.contains('m3u8') || videoUrl.contains('mp4'))
            ? pattern.firstMatch(videoUrl)?.group(0) ?? ''
            : videoUrl;
      } else {
        // 否则遍历所有属性，筛选符合条件的属性值
        for (var attr in videoAttributes.values) {
          var at = attr as String;
          if (pattern.hasMatch(at)) {
            videoUrl = pattern.firstMatch(at)?.group(0) ?? '';
          }
        }
      }
      // 如果videoUrl为空，尝试从playerVideoSelector中获取文本内容
      if (videoUrl.trim().isEmpty) {
        videoUrl = doc.querySelector(rule.playerVideoSelector)?.text ?? '';
      }
      if (videoUrl.trim().isEmpty) {
        videoUrl =
            doc.querySelector(rule.playerVideoSelector)?.attributes['src'] ??
            '';
      }
      _logger.d("fetch_view_videoUrl:$videoUrl");
      return videoUrl;
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
  }
}
