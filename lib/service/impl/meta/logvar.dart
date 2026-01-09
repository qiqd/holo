import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:holo/entity/danmu_item.dart';
import 'package:holo/entity/logvar_episode.dart';
import 'package:holo/util/http_util.dart';

class Logvar {
  static final baseUrl = dotenv.env["DAMMAKU_SERVER_URL"] ?? "";

  Future<List<LogvarEpisode>> fetchEpisodeFromLogvar(
    String keyword,
    Function(String) exception,
  ) async {
    try {
      final response = await HttpUtil.createDio().get(
        '$baseUrl/api/v2/search/episodes',
        queryParameters: {'anime': keyword},
      );
      if (response.statusCode == 200) {
        var data = response.data as Map<String, dynamic>;
        var animes = data['animes'] as List;
        return animes.map((item) {
          return LogvarEpisode.fromJson(item);
        }).toList();
      }
      return [];
    } catch (e) {
      log("Logvar.fetchEpisodeFromLogvar error: ${e.toString()}");
      exception(e.toString());
      return [];
    }
  }

  Future<Danmu?> fetchDammakuSync(
    int episodeId,
    void Function(String) exception, {
    int chConvert = 0,
  }) async {
    try {
      final response = await HttpUtil.createDio().get(
        '$baseUrl/api/v2/comment/$episodeId',
        queryParameters: {"withRelated": true, "chConvert": chConvert},
      );
      if (response.statusCode == 200) {
        var map = response.data as Map<String, dynamic>;
        var count = map["count"] as int;
        var comments = map['comments'] as List;
        var danmu = comments.map((item) {
          var map2 = item as Map<String, dynamic>;
          var cid = map2['cid'] as int;
          var p = map2["p"] as String;
          var text = map2["m"] as String;
          var pArr = p.split(",");
          return DanmuItem(
            cid: cid,
            time: double.parse(pArr[0]),
            type: int.parse(pArr[1]),
            color: int.parse(pArr[2]),
            text: text,
          );
        }).toList();
        return Danmu(count: count, comments: danmu);
      }
      return null;
    } catch (e) {
      log("Logvar.fetchDammakuSync error: ${e.toString()}");
      exception(e.toString());
      return null;
    }
  }
}
