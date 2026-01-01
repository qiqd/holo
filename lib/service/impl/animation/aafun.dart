import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';

import 'package:html/parser.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/http_util.dart';

class AAfun implements SourceService {
  @override
  int delay = 9999;
  @override
  String getBaseUrl() {
    return "https://www.aafun.cc";
  }

  @override
  String getLogoUrl() {
    return "https://p.upyun.com/demo/tmp/Hds66ovM.png";
  }

  @override
  String getName() {
    return "风铃动漫";
  }

  @override
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(dynamic) exceptionHandler,
  ) async {
    try {
      final res = await HttpUtil.createDio().get(getBaseUrl() + mediaId);
      if (res.statusCode == 200) {
        final document = parse(res.data);
        final items = document.querySelectorAll("div.hl-tabs-box");
        final sources = items.map((div) {
          final sourceElement = div.querySelectorAll("li.hl-col-xs-4 a");
          final episodes = sourceElement.map((a) {
            return a.attributes["href"]!;
          }).toList();
          return Line(episodes: episodes);
        }).toList();
        return Detail(lines: sources);
      }
      return null;
    } catch (e) {
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
    String searchUrl = "/feng-s.html?wd=${keyword.replaceAll(" ", "")}";
    try {
      final response = await HttpUtil.createDio().get(getBaseUrl() + searchUrl);
      if (response.statusCode == 200) {
        final document = parse(response.data);
        return document
            .querySelectorAll("div.hl-list-wrap li.hl-list-item")
            .map((li) {
              final a = li.querySelector("div.hl-item-div a");
              var type = li.querySelector("p.hl-item-sub.hl-lc-1")?.text;
              return Media(
                id: a?.attributes["href"],
                title: a?.attributes["title"],
                type: type?.trim(),
                coverUrl: a?.attributes["data-original"],
              );
            })
            .toList();
      }
      return [];
    } catch (e) {
      exceptionHandler(e);
      return [];
    }
  }

  String decryptAES(String ciphertext, String key) {
    try {
      final rawBytes = base64.decode(ciphertext);
      final ivBytes = rawBytes.sublist(0, 16);
      final encryptedBytes = rawBytes.sublist(16);
      final keyBytes = Uint8List.fromList(utf8.encode(key));
      final keyData = Key(keyBytes);
      final iv = IV(ivBytes);
      final encrypter = Encrypter(AES(keyData, mode: AESMode.cbc));
      final encrypted = Encrypted(encryptedBytes);
      final plainText = encrypter.decrypt(encrypted, iv: iv);
      return plainText;
    } catch (e) {
      throw Exception('AES解密失败: ${e.toString()}');
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
        final document = parse(response.data);
        final script = document.querySelectorAll(
          "script[type='text/javascript']",
        );
        final scriptElement = script.firstWhere(
          (s) => s.text.contains("var player_aaaa"),
        );
        final jsonStr =
            json.decode(
                  scriptElement.text.substring(scriptElement.text.indexOf("{")),
                )
                as Map<String, dynamic>;
        final url = Uri.decodeComponent(jsonStr["url"] as String);
        final targetUrl = "${getBaseUrl()}/player/?url=$url";
        final res = await HttpUtil.createDio().get(
          targetUrl,
          options: Options(
            headers: {
              "Host": getBaseUrl().substring(getBaseUrl().lastIndexOf("/") + 1),
              "Referer": getBaseUrl() + episodeId,
              "User-Agent":
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            },
          ),
        );
        if (res.statusCode != 200) {
          return null;
        }

        final scriptElement2 = parse(res.data).querySelectorAll("script");
        final scriptContent = scriptElement2.firstWhere(
          (s) => s.text.contains("const encryptedUrl"),
        );
        String? encryptedUrl;
        String? sessionKey;
        if (scriptContent.text.contains("const encryptedUrl")) {
          final encryptedUrlRegExp = RegExp(
            r'const\s+encryptedUrl\s*=\s*"([^"]+)"',
          );
          final encryptedUrlMatch = encryptedUrlRegExp.firstMatch(
            scriptContent.text,
          );
          if (encryptedUrlMatch != null) {
            encryptedUrl = encryptedUrlMatch.group(1);
          }
        }

        if (scriptContent.text.contains("const sessionKey")) {
          final sessionKeyRegExp = RegExp(
            r'const\s+sessionKey\s*=\s*"([^"]+)"',
          );
          final sessionKeyMatch = sessionKeyRegExp.firstMatch(
            scriptContent.text,
          );
          if (sessionKeyMatch != null) {
            sessionKey = sessionKeyMatch.group(1);
          }
        }
        if (encryptedUrl != null && sessionKey != null) {
          try {
            final decryptedUrl = decryptAES(encryptedUrl, sessionKey);
            return decryptedUrl.replaceFirst("http://", "https://");
          } catch (e) {
            log('解密失败: $e');
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      exceptionHandler(e);
      return null;
    }
  }
}
