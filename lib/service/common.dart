import 'dart:developer';

import 'package:holo/entity/media.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/webview_util.dart';
import 'package:html/parser.dart';

class Common extends SourceService {
  final Rule rule;
  final pattern = RegExp(
    r'https?://[^?&\s]*?\.(?:m3u8|mp4)(?:\?[^&\s]*)?(?=&|\s|$)',
    caseSensitive: false,
  );
  final RegExp reg = RegExp(r'\{[^}]*\}');
  final WebviewUtil webviewUtil = WebviewUtil();
  Common({required this.rule});
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
      final htmlStr = await webviewUtil.fetchHtml(
        rule.baseUrl + rule.detailUrl.replaceAll(reg, mediaId),
        timeout: Duration(seconds: rule.timeout),
        headers: rule.detailRequestHeaders,
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
      final htmlStr = await webviewUtil.fetchHtml(
        rule.baseUrl + rule.searchUrl.replaceAll(reg, keyword),
        timeout: Duration(seconds: rule.timeout),
        headers: rule.searchRequestHeaders,
        onError: exceptionHandler,
      );
      // log("htmlStr:$htmlStr");
      var doc = parse(htmlStr);
      return doc
          .querySelectorAll(rule.searchSelector)
          .map(
            (e) => Media(
              id:
                  e.querySelector(rule.itemIdSelector)?.attributes['href'] ??
                  '',
              title: e.querySelector(rule.itemTitleSelector)?.text ?? '',
              coverUrl:
                  e
                      .querySelector(rule.itemImgSelector)
                      ?.attributes[rule.itemImgFromSrc
                      ? 'src'
                      : 'data-original'] ??
                  '',

              type:
                  (rule.itemGenreSelector != null &&
                      rule.itemGenreSelector!.isNotEmpty)
                  ? e.querySelector(rule.itemGenreSelector!)?.text
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      exceptionHandler(e.toString());
      return [];
    }
  }

  @override
  Future<String?> fetchView(
    String episodeId,
    Function(String) exceptionHandler,
  ) async {
    try {
      final htmlStr = await webviewUtil.fetchHtml(
        rule.baseUrl + rule.playerUrl.replaceAll(reg, episodeId),
        timeout: Duration(seconds: rule.timeout),
        isPlayerPage: true,
        headers: rule.playerRequestHeaders,
        waitForMediaElement: rule.waitForMediaElement,
        onError: exceptionHandler,
      );
      // log("htmlStr:$htmlStr");
      var doc = parse(htmlStr);
      if (rule.embedVideoSelector != null &&
          rule.embedVideoSelector!.isNotEmpty) {
        var embedSelectors = rule.embedVideoSelector!.split(',');
        for (var selector in embedSelectors) {
          var tempUrl = doc.querySelector(selector)?.attributes['src'] ?? '';
          var tempHtmlStr = await webviewUtil.fetchHtml(
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
      var videoElement = doc.querySelector(rule.playerVideoSelector);

      var videoAttributes = videoElement?.attributes ?? {};
      var videoUrl = '';
      for (var attr in videoAttributes.values) {
        var at = attr as String;
        if (pattern.hasMatch(at)) {
          videoUrl = pattern.firstMatch(at)?.group(0) ?? '';
        }
      }
      // var videoUrl =
      //     doc
      //         .querySelector(rule.playerVideoSelector)
      //         ?.attributes[rule.videoElementAttribute ?? 'src'] ??
      //     '';
      // 如果videoUrl为空，尝试从playerVideoSelector中获取文本内容
      if (videoUrl.isEmpty) {
        videoUrl = doc.querySelector(rule.playerVideoSelector)?.text ?? '';
      }
      // if (rule.videoUrlSubsChar != null && rule.videoUrlSubsChar!.isNotEmpty) {
      //   videoUrl = videoUrl.split(rule.videoUrlSubsChar!).last;
      // }
      // log('fetch_view_videoUrl==${DateTime.now().millisecond}==}:$videoUrl');
      //return videoUrl;
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
    return null;
  }
}
