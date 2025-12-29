import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:mobile_holo/entity/playback_history.dart';
import 'package:mobile_holo/util/local_store.dart';

class PlayBackApi {
  static String serverUrl = "";
  static String token = "";

  static Dio dio = Dio();
  static void initServer() {
    serverUrl = LocalStore.getServerUrl() ?? "https://localhost:8080";
    token = LocalStore.getToken() ?? "";
    dio.options = BaseOptions(
      headers: {"Authorization": token, "User-Agent": "Holo/client"},
      baseUrl: "$serverUrl/history",
      contentType: "application/json",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  static Future<List<PlaybackHistory>> fetchPlaybackHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return [];
      }
      final response = await dio.get("/query/playback");
      if (response.statusCode == 200) {
        return (response.data as List).map((item) {
          var p = PlaybackHistory.fromJson(item);
          return p;
        }).toList();
      }
      return [];
    } catch (e) {
      log("Record getPlaybackHistory error: $e");
      exceptionHandler(e.toString());
      return [];
    }
  }

  static Future<PlaybackHistory?> fetchPlaybackHistoryBySubId(
    int subId,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.get("/query/playback/$subId");
      if (response.statusCode == 200) {
        return PlaybackHistory.fromJson(response.data);
      }
      return null;
    } catch (e) {
      log("Record getPlaybackHistory error: $e");
      exceptionHandler(e.toString());
      return null;
    }
  }

  static Future<void> deleteAllPlaybackRecord(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/delete/playback");
      if (response.statusCode != 200) {
        exceptionHandler.call("删除所有播放记录失败");
      } else {
        successHandler();
      }
    } catch (e) {
      log("Record deleteAllPlaybackRecordBySubId error: $e");
      exceptionHandler(e.toString());
    }
  }

  static Future<void> deleteAllPlaybackRecordBySubId(
    int subId,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/delete/playback/$subId");
      if (response.statusCode != 200) {
        exceptionHandler.call("删除所有播放记录失败");
      } else {
        successHandler();
      }
    } catch (e) {
      log("Record deleteAllPlaybackRecordBySubId error: $e");
      exceptionHandler(e.toString());
    }
  }

  static Future<PlaybackHistory?> savePlaybackHistory(
    PlaybackHistory playback,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.post("/save/playback", data: playback);
      if (response.statusCode != 200) {
        exceptionHandler.call("保存播放记录失败");
      }
      successHandler();
      return PlaybackHistory.fromJson(response.data);
    } catch (e) {
      log("Record savePlaybackHistory error: $e");
      exceptionHandler(e.toString());
    }
    return null;
  }
}
