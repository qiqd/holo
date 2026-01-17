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
      name: "厂长影视",
      baseUrl: 'https://www.czzymovie.com',
      logoUrl:
          'https://cf.hbcn.fun/wp-content/uploads/2021/08/19dc1c424e7c33-e1695868187732.png',
      searchUrl: 'https://www.yinghuadongman.com.cn/u/?wd={keyword}',
      itemImgSelector: 'img',
      itemTitleSelector: 'h2',
      itemIdSelector: 'a',
      itemImgFromSrc: false,
      detailUrl: 'https://www.yinghuadongman.com.cn{mediaId}',
      lineSelector: 'div.paly_list_btn',
      episodeSelector: 'a',
      playerUrl: '',
      searchSelector: 'article.u-movie',

      playerVideoSelector: 'iframe.viframe',
      videoUrlSubsChar: '=',
    ),
  });
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
        rule.detailUrl.replaceAll('{mediaId}', mediaId),
        timeout: const Duration(seconds: 60),
        onError: exceptionHandler,
      );
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
        rule.searchUrl.replaceAll('{keyword}', keyword),
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
        episodeId,
        timeout: const Duration(seconds: 60),
        onError: exceptionHandler,
      );
      log("htmlStr:$htmlStr");
      var doc = parse(htmlStr);
      var videoUrl =
          doc.querySelector(rule.playerVideoSelector)?.attributes['src'] ?? '';
      if (rule.videoUrlSubsChar != null) {
        videoUrl = videoUrl.split(rule.videoUrlSubsChar!).last;
      }
      return videoUrl;
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
  }
}
