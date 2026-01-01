import 'dart:convert';
import 'dart:developer';

import 'package:html/parser.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/http_util.dart';

class Senfen implements SourceService {
  @override
  int delay = 9999;
  @override
  String getBaseUrl() {
    return "https://senfun.in/";
  }

  @override
  String getLogoUrl() {
    return "https://senfun.in/static/senfun/upload/dyxscms/20211201-1/41c4d0a159b80ec48e50a26de1374041.gif";
  }

  @override
  String getName() {
    return "森之屋";
  }

  @override
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(dynamic) exceptionHandler,
  ) async {
    try {
      final response = await HttpUtil.createDio().get(getBaseUrl() + mediaId);
      if (response.statusCode == 200) {
        var document = response.data;
        var html = parse(document as String);
        var detail = html.querySelectorAll(
          "div.module-play-list-content.module-play-list-base",
        );
        var lines = detail.map((item) {
          var a = item.querySelectorAll("a");
          var episodes = a.map((i) => i.attributes["href"] ?? "").toList();
          return Line(episodes: episodes);
        }).toList();
        return Detail(lines: lines);
      }
      return null;
    } catch (e) {
      log("Senfen fetchDetail error: $e");
      exceptionHandler(e);
      return null;
    }
  }

  @override
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    Function(dynamic) exceptionHandler,
  ) async {
    final searchUrl = "${getBaseUrl()}search.html?wd=$keyword";
    try {
      final response = await HttpUtil.createDio().get(searchUrl);
      if (response.statusCode == 200) {
        var document = response.data;
        var html = parse(document as String);
        var detail = html.querySelectorAll("div.module-card-item.module-item");
        return detail.map((item) {
          var id =
              item
                  .querySelector("a.module-card-item-poster")
                  ?.attributes["href"] ??
              "";
          var infoBox = item.querySelector("div.module-item-pic img");
          var cover = infoBox?.attributes["data-original"];
          var title = infoBox?.attributes["alt"];
          var status = item
              .querySelector("div.module-info-item-content")
              ?.text
              .trim();
          return Media(id: id, type: status, coverUrl: cover, title: title);
        }).toList();
      }
      return [];
    } catch (e) {
      log("Senfen fetchSearch error: $e");
      exceptionHandler(e);
      return [];
    }
  }

  @override
  Future<String?> fetchView(
    String episodeId,
    Function(dynamic) exceptionHandler,
  ) async {
    try {
      final response = await HttpUtil.createDio().get(getBaseUrl() + episodeId);
      if (response.statusCode == 200) {
        var document = response.data;
        var html = parse(document as String);
        var detail = html
            .querySelectorAll("script[type='text/javascript']")
            .firstWhere(
              (item) =>
                  item.text.contains("(document).ready (function (argument)"),
            );
        RegExp pattern1 = RegExp(r'url:"([^"]+)"');
        RegExpMatch? match1 = pattern1.firstMatch(detail.text);
        if (match1 == null) {
          return null;
        }
        var url = match1.group(1);
        final response2 = await HttpUtil.createDio().get(getBaseUrl() + url!);
        if (response2.statusCode == 200) {
          var document2 = response2.data;
          var decode = json.decode(document2 as String) as Map<String, dynamic>;
          var list = decode["video_plays"] as List<dynamic>;
          var first = list.first as Map<String, dynamic>;
          return first["play_data"] as String? ?? "";
        }
      }
      return null;
    } catch (e) {
      log("Senfen fetchView error: $e");
      exceptionHandler(e);
      return null;
    }
  }
}
