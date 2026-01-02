import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

class PlayBackApi {
  static Dio dio = HttpUtil.createDioWithInterceptor();
  static Future<List<PlaybackHistory>> fetchPlaybackHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return [];
      }
      final response = await dio.get("/playback/query");
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
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.get("/playback/query/$subId");
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
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/playback/delete");
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

  static Future<void> deletePlaybackRecordBySubId(
    int subId,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/playback/delete/$subId");
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
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.post(
        "/playback/save",
        data: playback.toJson(),
      );
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
