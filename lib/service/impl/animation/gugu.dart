import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/common.dart';
import 'package:holo/util/http_util.dart';
import 'package:html/parser.dart';

class Gugu extends Common {
  Gugu()
    : super(
        rule: Rule(
          name: "Gugu",
          baseUrl: "https://www.gugu3.com",
          logoUrl:
              "https://www.gugu3.com/upload/site/20230512-1/8d3bab2eb1440259baad5079c0a28071.png",
          useWebView: false,
          searchUrl: "/index.php/vod/search.html?wd={keyword}",
          fullSearchUrl: false,
          searchRequestMethod: RequestMethod.get,
          searchSelector: "div.search-box",
          itemIdSelector: "div.thumb-menu>a",
          itemTitleSelector: "div.thumb-txt",
          itemImgSelector: "a.public-list-exp>img",
          itemImgFromSrc: false,
          itemGenreSelector: "div.thumb-else",
          detailUrl: "{mediaId}",
          fullDetailUrl: false,
          detailRequestMethod: RequestMethod.get,
          lineSelector: "ul.anthology-list-play",
          episodeSelector: "li>a",
          episodeReverse: false,
          timeout: 100,
        ),
      );

  @override
  Future<String?> fetchVideoUrl(
    String episodeId,
    Function(String) exceptionHandler,
  ) async {
    final fullUrl = getBaseUrl() + episodeId;
    try {
      var res = await HttpUtil.createDio(
        timeout: Duration(seconds: rule.timeout),
        referer: getBaseUrl(),
      ).get<String>(fullUrl);

      if ((res.data as String).isNotEmpty) {
        final document = parse(res.data as String);
        final script = document.querySelectorAll(
          "script[type='text/javascript']",
        );
        final scriptElement = script.firstWhere(
          (s) => s.text.contains("var player_aaa"),
        );
        final jsonStr =
            json.decode(
                  scriptElement.text.substring(scriptElement.text.indexOf("{")),
                )
                as Map<String, dynamic>;
        final url = jsonStr["url"] as String;
        final urlNext = jsonStr["link_next"] as String;

        //https://player.gugu3.com/?url=vwnet-355bd5afebd8dc9e9bf20a2df313d0a6&next=//www.gugu3.com/index.php/vod/play/id/4885/sid/2/nid/2.html
        final requestUrl =
            "${"https://player.gugu3.com/"}?url=$url&next=${Uri.parse(getBaseUrl()).host}$urlNext";
        final res2 = await HttpUtil.createDio(
          timeout: Duration(seconds: rule.timeout),
          referer: getBaseUrl(),
        ).get<String>(requestUrl);
        final temp = res2.data as String;
        final playerHtml = parse(temp);
        final playerScript = playerHtml.querySelectorAll(
          "script[type='text/javascript']",
        );
        final playerConfig = playerScript.firstWhere(
          (s) => s.text.contains("config"),
        );
        final RegExp reg = RegExp(
          r'var\s+config\s*=\s*(\{[\s\S]*?\});',
          caseSensitive: false,
          multiLine: true,
        );
        var config = reg.firstMatch(playerConfig.text)?.group(1) ?? '';
        String? encryptedUrl = RegExp(
          r'"url"\s*:\s*"([^"]+)"',
        ).firstMatch(config)?.group(1);

        String? time = RegExp(
          r'"time"\s*:\s*"([^"]+)"',
        ).firstMatch(config)?.group(1);

        String? vkey = RegExp(
          r'"vkey"\s*:\s*"([^"]+)"',
        ).firstMatch(config)?.group(1);

        var res3 =
            await HttpUtil.createDio(
              timeout: Duration(seconds: rule.timeout),
              referer: getBaseUrl(),
            ).post<String>(
              "https://player.gugu3.com/admin/mizhi_json.php",
              data: {"url": encryptedUrl, "time": time, "vkey": vkey},
              options: Options(contentType: Headers.formUrlEncodedContentType),
            );
        final jsonMap =
            json.decode(res3.data as String) as Map<String, dynamic>;
        return jsonMap["url"] as String;
      }
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
    return null;
  }
}
