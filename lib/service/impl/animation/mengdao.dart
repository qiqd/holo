import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:html/parser.dart';
import 'package:holo/entity/media.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/http_util.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';

class Mengdao implements SourceService {
  static const String _aesKey = "Mann20230627daoo";
  static const String _aesIv = "2023062720230627";
  @override
  int delay = 9999;
  @override
  String getBaseUrl() {
    return "https://www.mengdao.tv";
  }

  @override
  String getLogoUrl() {
    return "https://www.mengdao.tv/templets/mengdao/images/logo.png";
  }

  @override
  String getName() {
    return "Mengdao";
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
        var detail = html.querySelectorAll("div.plist.clearfix");
        var lines = detail.map((item) {
          var li = item.querySelectorAll("ul.urlli li");
          var episodes = li
              .map((i) => i.querySelector("a")?.attributes["href"] ?? "")
              .toList();
          return Line(episodes: episodes);
        }).toList();
        return Detail(lines: lines);
      }
      return null;
    } catch (e) {
      log("Mengdao fetchDetail error: $e");
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
      var searchUrl =
          "${getBaseUrl()}/search.php?searchword=${keyword.replaceAll(" ", "")}";
      final response = await HttpUtil.createDio().get(searchUrl);
      if (response.statusCode == 200) {
        var document = response.data;
        var html = parse(document as String);
        var res = html.querySelectorAll("div.index-tj.mb.clearfix ul li");
        return res.map((item) {
          var id = item.querySelector("a")?.attributes["href"] ?? "";
          var img = item.querySelector("div.img img");
          return Media(
            id: id,
            title: img?.attributes["alt"] ?? "",
            coverUrl: img?.attributes["data-original"] ?? "",
          );
        }).toList();
      }
      return [];
    } catch (e) {
      log("Mengdao fetchSearch error: $e");
      exceptionHandler(e);
      return [];
    }
  }

  @override
  Future<String?> fetchPlaybackUrl(
    String episodeId,
    Function(dynamic) exceptionHandler,
  ) async {
    try {
      final response = await HttpUtil.createDio().get(getBaseUrl() + episodeId);
      final doc = parse(response.data as String);

      final scripts = doc.querySelectorAll("script").where((element) {
        return element.text.contains("base64decode");
      }).toList();

      if (scripts.isEmpty) {
        log("未找到视频信息脚本, episodeId: $episodeId");
        return null;
      }
      String data = scripts[0].text;
      String videoInfo = data.substring(
        data.indexOf("(") + 2,
        data.lastIndexOf(")") - 1,
      );

      List<int> decode = base64Decode(videoInfo);
      String decodedVideoInfo = utf8.decode(decode);

      // 执行AES解密 - 使用NoPadding模式
      List<int> decryptedBytes = aesDecryptNoPadding(
        decodedVideoInfo,
        _aesKey,
        _aesIv,
      );

      // 手动去除ZeroPadding填充（ZeroPadding在末尾补0）
      int endIndex = decryptedBytes.length;
      for (int i = decryptedBytes.length - 1; i >= 0; i--) {
        if (decryptedBytes[i] != 0) {
          endIndex = i + 1;
          break;
        }
      }
      // 复制有效数据
      List<int> validData = decryptedBytes.sublist(0, endIndex);
      String result = utf8.decode(validData);
      var epsList = result
          .split("#")
          .map((s) {
            return s.substring(s.indexOf("\$") + 1, s.lastIndexOf("\$"));
          })
          .map((s) {
            return s.replaceAll(RegExp(r'\$[^$]*\$'), '');
          })
          .toList();
      var episodeIndex = episodeId.substring(
        episodeId.lastIndexOf("-") + 1,
        episodeId.lastIndexOf("."),
      );
      var videoData = epsList[int.parse(episodeIndex)];

      return videoData.replaceAll("http://", "https://");
    } catch (e) {
      log("Mengdao fetchView error: $e");
      exceptionHandler(e);
      return null;
    }
  }

  VideoData parseVideoData(String decryptedData) {
    VideoData videoData = VideoData();

    // 按$$$分割不同的播放源
    List<String> sources = decryptedData.split(r'$$$');

    for (String source in sources) {
      // 按$$分割播放源名称和视频列表
      List<String> parts = source.split(r'$$');
      if (parts.length >= 2) {
        String sourceName = parts[0]; // 播放源名称，如"云播放"、"极速播放"
        String videoList = parts[1]; // 视频列表数据

        // 解析视频列表
        List<VideoEpisode> episodes = [];

        // 按$xxx#模式分割不同的集数
        List<String> episodeBlocks = videoList.split(RegExp(r'\$\w+#'));
        for (String block in episodeBlocks) {
          // 按$分割集数信息
          List<String> episodeInfo = block.split(r'$');
          if (episodeInfo.length >= 3) {
            VideoEpisode episode = VideoEpisode();
            episode.title = episodeInfo[0]; // 集数标题，如"第1集"
            episode.m3u8Url = episodeInfo[1]; // M3U8地址
            episode.playerType = episodeInfo[2]; // 播放器类型
            episodes.add(episode);
          }
        }

        videoData.sources[sourceName] = episodes;
      }
    }

    return videoData;
  }

  // AES解密函数 - 使用NoPadding模式，匹配Java实现
  List<int> aesDecryptNoPadding(String encryptedBase64, String key, String iv) {
    try {
      // 将密钥和IV转换为字节
      Uint8List keyBytes = Uint8List.fromList(utf8.encode(key));
      Uint8List ivBytes = Uint8List.fromList(utf8.encode(iv));

      // Base64解码加密的数据
      Uint8List encryptedBytes = base64Decode(encryptedBase64);

      // 创建AES解密器
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(keyBytes), ivBytes);
      cipher.init(false, params);

      // 执行解密
      Uint8List output = Uint8List(encryptedBytes.length);
      int offset = 0;
      while (offset < encryptedBytes.length) {
        offset += cipher.processBlock(encryptedBytes, offset, output, offset);
      }

      return output.toList();
    } catch (e) {
      log("AES解密错误: $e");
      rethrow;
    }
  }
}

class VideoEpisode {
  String? title; // 集数标题，如"第1集"
  String? m3u8Url; // M3U8播放地址
  String? playerType; // 播放器类型

  VideoEpisode({this.title, this.m3u8Url, this.playerType});
}

class VideoData {
  // 播放源映射: 播放源名称 -> 视频集数列表
  Map<String, List<VideoEpisode>> sources = {};

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    for (String source in sources.keys) {
      sb.write("播放源: $source\n");
      List<VideoEpisode> episodes = sources[source] ?? [];
      for (int i = 0; i < episodes.length; i++) {
        sb.write(
          "  第${i + 1}集: ${episodes[i].title} - ${episodes[i].m3u8Url}\n",
        );
      }
    }
    return sb.toString();
  }
}
