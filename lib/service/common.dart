import 'dart:developer';
import 'package:holo/entity/media.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/flutter_inappwebview.dart';
import 'package:html/parser.dart';

class Common extends SourceService {
  final Rule rule;
  final pattern = RegExp(
    r'https?://[^?&\s]*?\.(?:m3u8|mp4)(?:\?[^&\s]*)?(?=&|\s|$)',
    caseSensitive: false,
  );
  final RegExp reg = RegExp(r'\{[^}]*\}');
  final FlutterInappwebview _webviewUtil = FlutterInappwebview();
  Common({required this.rule}) {
    _webviewUtil.fetchHtml(rule.baseUrl);
  }
  factory Common.build(Rule rule) => Common(rule: rule);
  @override
  String getBaseUrl() {
    return rule.baseUrl;
  }

  @override
  String getLogoUrl() {
    return rule.logoUrl;
  }

  @override
  String getName() {
    return rule.name;
  }

  @override
  int delay = 9999;

  @override
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(String) exceptionHandler,
  ) async {
    try {
      var detailUrl = rule.baseUrl + rule.detailUrl.replaceAll(reg, mediaId);
      final htmlStr = await _webviewUtil.fetchHtml(
        mediaId.contains('http') ? mediaId : detailUrl,
        requestMethod: rule.detailRequestMethod,
        timeout: Duration(seconds: rule.timeout),
        headers: rule.detailRequestHeaders,
        requestBody: rule.detailRequestBody.map(
          (key, value) => MapEntry(key, value.replaceAll('{mediaId}', mediaId)),
        ),
        onError: exceptionHandler,
      );
      //log("detail-htmlStr:$htmlStr");
      var doc = parse(htmlStr);
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
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    Function(String) exceptionHandler, {
    timeout = const Duration(seconds: 60),
  }) async {
    try {
      var searchUrl = rule.baseUrl + rule.searchUrl.replaceAll(reg, keyword);
      final htmlStr = await _webviewUtil.fetchHtml(
        keyword.contains('http') ? keyword : searchUrl,
        requestMethod: rule.searchRequestMethod,
        requestBody: rule.searchRequestBody.map(
          (key, value) => MapEntry(key, value.replaceAll('{keyword}', keyword)),
        ),
        timeout: Duration(seconds: rule.timeout),
        headers: rule.searchRequestHeaders,
        onError: exceptionHandler,
      );
      // log("htmlStr:$htmlStr");
      var doc = parse(htmlStr);
      var imgAttrs = ['data-original', 'data-src'];
      return doc.querySelectorAll(rule.searchSelector).map((e) {
        var imgUrl = '';
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
        imgUrl = imgUrl.contains('http') ? imgUrl : rule.baseUrl + imgUrl;

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
  Future<String?> fetchPlaybackUrl(
    String episodeId,
    Function(String) exceptionHandler,
  ) async {
    try {
      var viewUrl = rule.baseUrl + rule.playerUrl.replaceAll(reg, episodeId);
      final htmlStr = await _webviewUtil.fetchHtml(
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
      );
      // log("htmlStr:$htmlStr");
      var doc = parse(htmlStr);
      //如果是嵌入式视频，需要获取最终的播放网页
      if (rule.embedVideoSelector != null &&
          rule.embedVideoSelector!.isNotEmpty) {
        var embedSelectors = rule.embedVideoSelector!.split(',');
        for (var selector in embedSelectors) {
          var tempUrl = doc.querySelector(selector)?.attributes['src'] ?? '';
          var tempHtmlStr = await _webviewUtil.fetchHtml(
            tempUrl,
            isPlayerPage: true,
            headers: rule.playerRequestHeaders,
            waitForMediaElement: rule.waitForMediaElement,
            timeout: Duration(seconds: rule.timeout),
          );
          doc = parse(tempHtmlStr);
          log(
            'embed selector==${DateTime.now().millisecond}==}:$selector, tempUrl:$tempUrl',
          );
          //  log('embed tempHtmlStr:$tempHtmlStr');
        }
      }
      // 从videoElement中获取视频URL
      var videoElement = doc.querySelector(rule.playerVideoSelector);
      var videoAttributes = videoElement?.attributes ?? {};
      var videoUrl = '';
      //如果规则中指定了视频元素属性，直接从属性中获取URL，否则遍历所有属性，筛选符合条件的属性值
      if (rule.videoElementAttribute != null &&
          rule.videoElementAttribute!.isNotEmpty) {
        videoUrl =
            doc
                .querySelector(rule.playerVideoSelector)
                ?.attributes[rule.videoElementAttribute!] ??
            '';
        videoUrl = videoUrl.contains('m3u8')
            ? pattern.firstMatch(videoUrl)?.group(0) ?? ''
            : videoUrl;
      } else {
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
      // if (rule.videoUrlSubsChar != null && rule.videoUrlSubsChar!.isNotEmpty) {
      //   videoUrl = videoUrl.split(rule.videoUrlSubsChar!).last;
      // }
      // log('fetch_view_videoUrl==${DateTime.now().millisecond}==}:$videoUrl');
      return videoUrl;
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
  }
}
