import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:html/parser.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/http_util.dart';

class Mwcy implements SourceService {
  @override
  int delay = 9999;
  @override
  String getBaseUrl() {
    return "https://www.mwcy.net";
  }

  @override
  String getLogoUrl() {
    return "https://www.mwcy.net/template/dsn2/static/img/logo1.png";
  }

  @override
  String getName() {
    return "喵物次元";
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
          var li = item.querySelectorAll("a");
          var episodes = li.map((i) => i.attributes["href"] ?? "").toList();
          return Line(episodes: episodes);
        }).toList();
        return Detail(lines: lines);
      }
      return null;
    } catch (e) {
      log("Mwcy fetchDetail error: $e");
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
          "${getBaseUrl()}/search/wd/${keyword.replaceAll(" ", "")}.html";
      final response = await HttpUtil.createDio().get(searchUrl);
      if (response.statusCode == 200) {
        var document = response.data;
        var html = parse(document as String);
        var res = html.querySelectorAll(
          "div.vod-detail.style-detail.cor4.search-list",
        );
        var medias = res.map((item) {
          var status = item
              .querySelectorAll("span.slide-info-remarks")
              .map((e) => e.text)
              .toList()
              .join("·");
          var box = item.querySelector("div.detail-pic img");
          var nameCn = box?.attributes["alt"] ?? "";
          var cover = box?.attributes["data-src"] ?? "";
          var id =
              item
                  .querySelector("div.detail-info.rel.flex-auto.lightSpeedIn a")
                  ?.attributes["href"] ??
              "";
          return Media(id: id, type: status, title: nameCn, coverUrl: cover);
        }).toList();
        return medias;
      }
      return [];
    } catch (e) {
      log("Mwcy fetchSearch error: $e");
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
        var res = html.querySelectorAll("script").firstWhere((item) {
          return item.text.contains("var player_aaaa");
        });
        var script = res.text;

        // // 方案2：更安全的匹配（处理转义）
        // RegExp pattern2 = RegExp(r'url:\"([^\"]+)\"');
        // //Pattern.compile("\"uid\"\\s*:\\s*\"([^\"]+)\"");
        // RegExp uidPattern = RegExp(r'"uid"\s*:\s*"([^\"]+)"');

        var playerAaa =
            json.decode(script.substring(script.indexOf("{")))
                as Map<String, dynamic>;

        // RegExpMatch? match2 = pattern2.firstMatch(script);
        String urlValue = playerAaa["url"] as String;
        final rs = await HttpUtil.createDio().get(
          "https://play.catw.moe/player/ec.php?code=qw&if=1&url=$urlValue",
        );
        if (rs.statusCode == 200) {
          var r = rs.data as String;
          var targetHtml = parse(r);
          var player = targetHtml.querySelectorAll("script").firstWhere((item) {
            return item.text.contains("let ConFig");
          });
          var playerScript = player.text.substring(
            player.text.indexOf("{"),
            player.text.lastIndexOf("b") - 1,
          );
          var config = json.decode(playerScript) as Map<String, dynamic>;
          var url = config["url"];
          var config2 = config["config"] as Map<String, dynamic>;
          var uid = config2["uid"] as String;
          uid = uid.replaceAll('\\', '/');
          return decryptVideoUrl(url, uid);
        }
      }
      return null;
    } catch (e) {
      log("Mwcy fetchView error: $e");
      exceptionHandler(e);
      return null;
    }
  }

  String decryptVideoUrl(String encryptedData, String uid) {
    try {
      // 1. 构建密钥
      String key = "2890${uid}tB959C";
      // 2. 固定向量
      String iv = "2F131BE91247866E";

      // Base64解码加密的数据
      Uint8List encryptedBytes = base64Decode(encryptedData);

      // 创建密钥和IV
      final keyBytes = Uint8List.fromList(utf8.encode(key));
      final ivBytes = Uint8List.fromList(utf8.encode(iv));

      // 使用encrypt包进行AES解密
      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key(keyBytes),
          mode: encrypt.AESMode.cbc,
          padding: 'PKCS7', // PKCS5和PKCS7在AES中是一样的
        ),
      );

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
        iv: encrypt.IV(ivBytes),
      );

      return utf8.decode(decrypted);
    } catch (e) {
      log("AES解密错误: $e");
      throw Exception("解密失败: $e");
    }
  }
}

class Response {
  List<Map<String, String>>? video_plays;
  String? html_content;
  Response({this.video_plays, this.html_content});
  factory Response.fromJson(Map<String, dynamic> json) => Response(
    video_plays: json["video_plays"] == null
        ? null
        : List<Map<String, String>>.from(json["video_plays"].map((x) => x)),
    html_content: json["html_content"],
  );
}
