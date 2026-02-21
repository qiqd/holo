import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

/// 播放历史相关API服务类
/// 提供播放历史的查询、删除和保存功能
class PlayBackApi {
  /// 带有拦截器的Dio实例
  static Dio dio = HttpUtil.createDioWithInterceptor();

  /// 获取所有播放历史
  /// [exceptionHandler] 异常回调
  /// 返回播放历史列表
  static Future<List<PlaybackHistory>> fetchPlaybackHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return [];
      }
      // 发起获取播放历史的请求
      final response = await dio.get("/playback/query");
      if (response.statusCode == 200) {
        // 解析响应数据
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

  /// 根据订阅ID获取播放历史
  /// [subId] 订阅ID
  /// [exceptionHandler] 异常回调
  /// 返回播放历史对象
  static Future<PlaybackHistory?> fetchPlaybackHistoryBySubId(
    int subId,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      // 发起获取指定订阅播放历史的请求
      final response = await dio.get("/playback/query/$subId");
      if (response.statusCode == 200) {
        // 解析响应数据
        return PlaybackHistory.fromJson(response.data);
      }
      return null;
    } catch (e) {
      log("Record getPlaybackHistory error: $e");
      exceptionHandler(e.toString());
      return null;
    }
  }

  /// 删除所有播放记录
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  static Future<void> deleteAllPlaybackRecord(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      // 发起删除所有播放记录的请求
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

  /// 根据订阅ID删除播放记录
  /// [subId] 订阅ID
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  static Future<void> deletePlaybackRecordBySubId(
    int subId,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      // 发起删除指定订阅播放记录的请求
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

  /// 保存播放历史
  /// [playback] 播放历史对象
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  /// 返回保存后的播放历史对象
  static Future<PlaybackHistory?> savePlaybackHistory(
    PlaybackHistory playback,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      // 发起保存播放历史的请求
      final response = await dio.post(
        "/playback/save",
        data: playback.toJson(),
      );
      if (response.statusCode != 200) {
        exceptionHandler.call("保存播放记录失败");
      }
      successHandler();
      // 解析响应数据
      return PlaybackHistory.fromJson(response.data);
    } catch (e) {
      log("Record savePlaybackHistory error: $e");
      exceptionHandler(e.toString());
    }
    return null;
  }
}
