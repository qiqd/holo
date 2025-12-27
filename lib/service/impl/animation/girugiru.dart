import 'dart:convert';
import 'dart:developer';

import 'package:html/parser.dart';
import 'package:mobile_holo/entity/media.dart';
import 'package:mobile_holo/service/source_service.dart';
import 'package:mobile_holo/util/http_util.dart';

class Girugiru implements SourceService {
  @override
  int delay = 9999;
  @override
  String getBaseUrl() {
    return "https://bgm.girigirilove.com";
  }

  @override
  String getLogoUrl() {
    return "https://bgm.girigirilove.com/upload/site/20251010-1/b84e444374bcec3a20419e29e1070e1b.png";
  }

  @override
  String getName() {
    return "Girugiri爱动漫";
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
        var detail = html.querySelectorAll("div.anthology-list-box.none");
        var lines = detail.map((item) {
          var a = item.querySelectorAll("a");
          var episodes = a.map((i) => i.attributes["href"] ?? "").toList();
          return Line(episodes: episodes);
        }).toList();

        return Detail(lines: lines);
      }
      return null;
    } catch (e) {
      log("Girugiru fetchDetail error: $e");
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
    try {
      final searchUrl =
          "${getBaseUrl()}/search/-------------/?wd=${keyword.replaceAll(" ", "")}";
      final response = await HttpUtil.createDio().get(searchUrl);
      if (response.statusCode == 200) {
        var document = response.data;
        var html = parse(document as String);
        var searchList = html.querySelectorAll("div.search-list");
        return searchList.map((item) {
          var id = item.querySelector("div.detail-info a")?.attributes["href"];
          var cover =
              item.querySelector("img.gen-movie-img")?.attributes["data-src"] ??
              "";
          var title = item
              .querySelector("img.gen-movie-img")
              ?.attributes["alt"];
          var statusCode = item.querySelectorAll(
            "div.detail-info.rel.flex-auto.lightSpeedIn div.slide-info.hide.this-wap",
          );
          var status = statusCode.map((e) => e.text).toList().join("·");
          return Media(
            id: id ?? "",
            type: status,
            title: title ?? "",
            coverUrl: getBaseUrl() + cover,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      log("Girugiru fetchSearch error: $e");
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
        var playerInfo = html
            .querySelectorAll("script")
            .firstWhere((element) => element.text.contains("player_aaaa"))
            .text;
        var jsonStr =
            json.decode(playerInfo.substring(playerInfo.indexOf("{")))
                as Map<String, dynamic>;
        var url = jsonStr["url"];
        var realUrl = decodeUrl(url);
        return realUrl;
      }
      return null;
    } catch (e) {
      log("Girugiru fetchView error: $e");
      exceptionHandler(e);
      return null;
    }
  }

  String decodeUrl(String encodedUrl) {
    if (encodedUrl.isEmpty) return encodedUrl;

    String decodedUrl = encodedUrl;

    try {
      try {
        List<int> decodedBytes = base64Decode(encodedUrl);
        decodedUrl = utf8.decode(decodedBytes);
      } catch (base64Exception) {
        try {
          decodedUrl = Uri.decodeComponent(encodedUrl);
        } catch (urlException) {
          decodedUrl = encodedUrl;
        }
      }

      try {
        String doubleDecodedUrl = Uri.decodeComponent(decodedUrl);
        if (doubleDecodedUrl != decodedUrl) {
          decodedUrl = doubleDecodedUrl;
        }
      } catch (e) {
        log("Girugiru decodeUrl error: $e");
      }
      return decodedUrl;
    } catch (e) {
      log("Girugiru decodeUrl error: $e");
      return encodedUrl;
    }
  }
}
