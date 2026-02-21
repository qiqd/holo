import 'dart:developer';
import 'package:holo/entity/media.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/flutter_inappwebview.dart';
import 'package:holo/util/http_util.dart';
import 'package:html/parser.dart';

/// 通用动画源服务类
/// 根据规则配置构建动画源服务
class Common extends SourceService {
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
  final FlutterInappwebview _webviewUtil = FlutterInappwebview();

  /// 构造函数
  /// [rule] 规则配置对象
  Common({required this.rule}) {
    if (rule.useWebView) {
      _webviewUtil.fetchHtml(rule.baseUrl);
    }
  }

  /// 工厂构造函数
  /// [rule] 规则配置对象
  factory Common.build(Rule rule) => Common(rule: rule);

  @override
  /// 获取网站基础地址
  String getBaseUrl() {
    return rule.baseUrl;
  }

  @override
  /// 获取网站logo地址
  String getLogoUrl() {
    return rule.logoUrl;
  }

  @override
  /// 获取服务名称
  String getName() {
    return rule.name;
  }

  @override
  /// 服务延迟时间
  int delay = 9999;

  @override
  /// 解析媒体详情信息
  /// [mediaId] 媒体ID
  /// [exceptionHandler] 异常处理器
  /// 返回详情信息对象
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(String) exceptionHandler,
  ) async {
    try {
      // 构建详情页URL
      var detailUrl = rule.baseUrl + rule.detailUrl.replaceAll(reg, mediaId);
      // 获取HTML内容
      final htmlStr = switch (rule.useWebView) {
        true => await _webviewUtil.fetchHtml(
          mediaId.contains('http') ? mediaId : detailUrl,
          requestMethod: rule.detailRequestMethod,
          timeout: Duration(seconds: rule.timeout),
          headers: rule.detailRequestHeaders,
          requestBody: rule.detailRequestBody.map(
            (key, value) =>
                MapEntry(key, value.replaceAll('{mediaId}', mediaId)),
          ),
          onError: exceptionHandler,
        ),
        false =>
          (await HttpUtil.createDio().get(
                mediaId.contains('http') ? mediaId : detailUrl,
              )).data
              as String,
      };

      // 解析HTML文档
      var doc = parse(htmlStr);
      // 提取剧集信息
      var lines = doc.querySelectorAll(rule.lineSelector).map((line) {
        final episode = line.querySelectorAll(rule.episodeSelector);
        var episodes = episode.map((e) {
          return e.attributes['href'] ?? '';
        }).toList();
        return Line(episodes: episodes);
      }).toList();
      return Detail(lines: lines);
    } catch (e) {
      exceptionHandler(e.toString());
    }
    return null;
  }

  @override
  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// [size] 每页数量
  /// [exceptionHandler] 异常处理器
  /// [timeout] 超时时间
  /// 返回媒体列表
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
        true => await _webviewUtil.fetchHtml(
          keyword.contains('http') ? keyword : searchUrl,
          requestMethod: rule.searchRequestMethod,
          requestBody: rule.searchRequestBody.map(
            (key, value) =>
                MapEntry(key, value.replaceAll('{keyword}', keyword)),
          ),
          timeout: Duration(seconds: rule.timeout),
          headers: rule.searchRequestHeaders,
          onError: exceptionHandler,
        ),
        false =>
          (await HttpUtil.createDio().get(
                keyword.contains('http') ? keyword : searchUrl,
              )).data
              as String,
      };
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
        imgUrl = imgUrl.contains("http") ? imgUrl : ('https://$imgUrl');
        // 构建媒体对象
        return Media(
          id: e.querySelector(rule.itemIdSelector)?.attributes['href'] ?? '',
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

  @override
  /// 解析播放地址
  /// [episodeId] 剧集ID
  /// [exceptionHandler] 异常处理器
  /// 返回播放地址字符串
  Future<String?> fetchPlaybackUrl(
    String episodeId,
    Function(String) exceptionHandler,
  ) async {
    try {
      // 构建播放页URL
      var viewUrl = rule.baseUrl + rule.playerUrl.replaceAll(reg, episodeId);
      // 获取HTML内容
      final htmlStr = switch (rule.useWebView) {
        true => await _webviewUtil.fetchHtml(
          episodeId.contains('http') ? episodeId : viewUrl,
          timeout: Duration(seconds: rule.timeout),
          requestMethod: rule.playerRequestMethod,
          requestBody: rule.playerRequestBody.map(
            (key, value) =>
                MapEntry(key, value.replaceAll('{episodeId}', episodeId)),
          ),
          isPlayerPage: true,
          headers: rule.playerRequestHeaders,
          waitForMediaElement: rule.waitForMediaElement,
          onError: exceptionHandler,
        ),
        false =>
          (await HttpUtil.createDio().get(
                episodeId.contains('http') ? episodeId : viewUrl,
              )).data
              as String,
      };
      // 解析HTML文档
      var doc = parse(htmlStr);
      // 处理嵌入式视频
      if (rule.embedVideoSelector != null &&
          rule.embedVideoSelector!.isNotEmpty) {
        var embedSelectors = rule.embedVideoSelector!.split(',');
        for (var selector in embedSelectors) {
          var tempUrl = doc.querySelector(selector)?.attributes['src'] ?? '';
          var tempHtmlStr = switch (rule.useWebView) {
            true => await _webviewUtil.fetchHtml(
              tempUrl.contains('http') ? tempUrl : (rule.baseUrl + tempUrl),
              isPlayerPage: true,
              headers: rule.playerRequestHeaders,
              waitForMediaElement: rule.waitForMediaElement,
              timeout: Duration(seconds: rule.timeout),
            ),
            false =>
              (await HttpUtil.createDio().get(
                    tempUrl.contains('http')
                        ? tempUrl
                        : (rule.baseUrl + tempUrl),
                  )).data
                  as String,
          };
          doc = parse(tempHtmlStr);
          log(
            'embed selector==${DateTime.now().millisecond}==}:$selector, tempUrl:$tempUrl',
          );
        }
      }
      // 从videoElement中获取视频URL
      var videoElement = doc.querySelector(rule.playerVideoSelector);
      var videoAttributes = videoElement?.attributes ?? {};
      var videoUrl = '';
      // 如果规则中指定了视频元素属性，直接从属性中获取URL
      if (rule.videoElementAttribute != null &&
          rule.videoElementAttribute!.isNotEmpty) {
        videoUrl =
            doc
                .querySelector(rule.playerVideoSelector)
                ?.attributes[rule.videoElementAttribute!] ??
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
      if (videoUrl.isEmpty) {
        videoUrl = doc.querySelector(rule.playerVideoSelector)?.text ?? '';
      }
      log('fetch_view_videoUrl==${DateTime.now().millisecond}==}:$videoUrl');
      return videoUrl;
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
  }
}
