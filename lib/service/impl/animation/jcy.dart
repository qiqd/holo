import 'dart:convert';

import 'package:holo/entity/rule.dart';
import 'package:holo/service/common.dart';
import 'package:holo/util/http_util.dart';
import 'package:html/parser.dart';

@Deprecated("baseurl 不可访问")
class Jcy extends Common {
  Jcy()
    : super(
        rule: Rule(
          name: "Jcy",
          baseUrl: "https://9ciyuan.net/",
          logoUrl:
              "https://www.jcydm.cc/upload/mxprocms/20241011-1/1a3278ead727085fb1f5ed30d14462b1.png",
          useWebView: false,
          searchUrl: "/vod-search.html?wd={keyword}",
          fullSearchUrl: false,
          searchRequestMethod: RequestMethod.get,
          searchSelector: " div.search-box",
          itemIdSelector: " div.thumb-txt>a",
          itemTitleSelector: "div.thumb-txt>a",
          itemImgSelector: "img.gen-movie-img",
          itemImgFromSrc: false,
          itemGenreSelector: "div.thumb-else",
          detailUrl: "{mediaId}",
          fullDetailUrl: false,
          detailRequestMethod: RequestMethod.get,
          lineSelector: "ul.anthology-list-play",
          episodeSelector: "li>a",
          episodeReverse: false,
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
        referer: getBaseUrl() + episodeId,
      ).get(fullUrl);

      if ((res.data as String).isNotEmpty) {
        final document = parse(res.data as String);
        final script = document.querySelectorAll(
          "script[type='text/javascript']",
        );
        final scriptElement = script.firstWhere(
          (s) => s.text.contains("var player_data"),
        );
        final jsonStr =
            json.decode(
                  scriptElement.text.substring(scriptElement.text.indexOf("{")),
                )
                as Map<String, dynamic>;
        return decodeEncodedUrl(
          jsonStr["url"] as String,
          jsonStr["encrypt"] as int,
        );
      }
    } catch (e) {
      exceptionHandler(e.toString());
      return null;
    }
    return null;
  }

  /// 解码网站的混淆 URL
  /// [encodedUrl] - 加密的 URL 字符串
  /// [encrypt] - 加密模式：1=直接URL解码，2=Base64解码后再URL解码
  String decodeEncodedUrl(String encodedUrl, int encrypt) {
    if (encrypt == 0) {
      return encodedUrl.replaceAll('\\', '');
    } else if (encrypt == 1) {
      // encrypt=1: 直接进行 URL 解码（unescape）
      return Uri.decodeFull(encodedUrl);
    } else if (encrypt == 2) {
      // encrypt=2: 先 Base64 解码，再 URL 解码
      const String base64Chars =
          "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      String decoded = '';
      int i = 0;

      while (i < encodedUrl.length) {
        int c1 = base64Chars.indexOf(encodedUrl[i++]);
        if (c1 == -1) break;

        int c2 = base64Chars.indexOf(encodedUrl[i++]);
        if (c2 == -1) break;

        decoded += String.fromCharCode((c1 << 2) | ((c2 & 0x30) >> 4));

        if (i >= encodedUrl.length) break;
        int c3 = base64Chars.indexOf(encodedUrl[i++]);
        if (c3 == -1 || encodedUrl[i - 1] == '=') break;

        decoded += String.fromCharCode(((c2 & 0xF) << 4) | ((c3 & 0x3C) >> 2));

        if (i >= encodedUrl.length) break;
        int c4 = base64Chars.indexOf(encodedUrl[i++]);
        if (c4 == -1 || encodedUrl[i - 1] == '=') break;

        decoded += String.fromCharCode(((c3 & 0x3) << 6) | c4);
      }

      return Uri.decodeFull(decoded);
    } else {
      // 默认返回原始字符串
      return encodedUrl;
    }
  }
}
