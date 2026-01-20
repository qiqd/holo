import 'dart:developer';

import 'package:holo/entity/media.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/webview_util.dart';
import 'package:html/parser.dart';

class Common extends SourceService {
  final Rule rule;
  Common({
    this.rule = const Rule(
      name: "樱花动漫",
      baseUrl: 'www.yinghuadongman.com.cn',
      logoUrl: 'www.yinghuadongman.com.cn/template/y/static/images/logo.jpg',
      searchUrl: 'www.yinghuadongman.com.cn/u/?wd={keyword}',
      fullSearchUrl: false,
      searchSelector: 'article.u-movie',
      itemImgSelector: 'div.list-poster img',
      itemTitleSelector: 'a',
      itemIdSelector: 'a',
      itemImgFromSrc: false,
      detailUrl: 'www.yinghuadongman.com.cn{mediaId}',
      fullDetailUrl: false,
      lineSelector: 'div.vlink',
      episodeSelector: 'a',
      playerUrl: 'www.yinghuadongman.com.cn{episodeId}',
      fullPlayerUrl: false,
      playerVideoSelector: 'td#playleft>iframe',
      videoUrlSubsChar: '=',
    ),
  });
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
      final htmlStr = await WebviewUtil.fetchHtml(
        rule.fullDetailUrl
            ? rule.detailUrl
            : rule.detailUrl.replaceAll('{mediaId}', mediaId),
        timeout: const Duration(seconds: 60),
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
      final htmlStr = await WebviewUtil.fetchHtml(
        rule.fullSearchUrl
            ? rule.searchUrl
            : rule.searchUrl.replaceAll('{keyword}', keyword),
        timeout: timeout,
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
      final htmlStr = await WebviewUtil.fetchHtml(
        rule.fullPlayerUrl
            ? rule.playerUrl
            : rule.playerUrl.replaceAll('{episodeId}', episodeId),
        timeout: Duration(seconds: rule.timeout),
        onError: exceptionHandler,
      );
      // log("htmlStr:$htmlStr");
      var doc = parse(htmlStr);
      if (rule.embedVideoSelector != null &&
          rule.embedVideoSelector!.isNotEmpty) {
        var embedSelectors = rule.embedVideoSelector!.split(',');
        for (var selector in embedSelectors) {
          var tempUrl = doc.querySelector(selector)?.attributes['src'] ?? '';
          var tempHtmlStr = await WebviewUtil.fetchHtml(
            tempUrl,
            timeout: Duration(seconds: rule.timeout),
          );
          doc = parse(tempHtmlStr);
          log('embed selector:$selector, tempUrl:$tempUrl');
          //  log('embed tempHtmlStr:$tempHtmlStr');
        }
      }

      var videoUrl =
          doc.querySelector(rule.playerVideoSelector)?.attributes['src'] ?? '';
      if (videoUrl.isEmpty) {
        videoUrl = doc.querySelector(rule.playerVideoSelector)?.text ?? '';
      }
      if (rule.videoUrlSubsChar != null && rule.videoUrlSubsChar!.isNotEmpty) {
        videoUrl = videoUrl.split(rule.videoUrlSubsChar!).last;
      }
      return videoUrl;
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
  }
}
