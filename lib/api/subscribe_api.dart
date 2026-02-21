import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

/// 订阅相关API服务类
/// 提供订阅历史的查询、删除和保存功能
class SubscribeApi {
  /// 带有拦截器的Dio实例
  static Dio dio = HttpUtil.createDioWithInterceptor();

  /// 获取所有订阅历史
  /// [exceptionHandler] 异常回调
  /// 返回订阅历史列表
  static Future<List<SubscribeHistory>> fetchSubscribeHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return [];
      }
      // 发起获取订阅历史的请求
      final response = await dio.get("/subscribe/query");
      if (response.statusCode == 200) {
        // 解析响应数据
        return (response.data as List).map((item) {
          var s = SubscribeHistory.fromJson(item);
          return s;
        }).toList();
      }
      return [];
    } catch (e) {
      log("Record getSubscribeHistory error: $e");
      exceptionHandler(e.toString());
      return [];
    }
  }

  /// 根据订阅ID获取订阅历史
  /// [subId] 订阅ID
  /// [exceptionHandler] 异常回调
  /// 返回订阅历史对象
  static Future<SubscribeHistory?> fetchSubscribeHistoryBySubId(
    int subId,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      // 发起获取指定订阅历史的请求
      final response = await dio.get("/subscribe/query/$subId");
      if (response.statusCode == 200) {
        // 解析响应数据
        return SubscribeHistory.fromJson(response.data);
      }
      return null;
    } catch (e) {
      log("Record getSubscribeHistory error: $e");
      exceptionHandler(e.toString());
      return null;
    }
  }

  /// 删除所有订阅记录
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  static Future<void> deleteAllSubscribeRecord(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      // 发起删除所有订阅记录的请求
      final response = await dio.delete("/subscribe/delete");
      if (response.statusCode != 200) {
        exceptionHandler.call("删除所有订阅记录失败");
      } else {
        successHandler();
      }
    } catch (e) {
      log("Record deleteAllSubscribeRecord error: $e");
      exceptionHandler(e.toString());
    }
  }

  /// 根据订阅ID删除订阅记录
  /// [subId] 订阅ID
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  static Future<void> deleteSubscribeRecordBySubId(
    int subId,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      // 发起删除指定订阅记录的请求
      final response = await dio.delete("/subscribe/delete/$subId");
      if (response.statusCode != 200) {
        exceptionHandler.call("删除订阅记录失败");
      } else {
        successHandler();
      }
    } catch (e) {
      log("Record deleteAllSubscribeRecord error: $e");
      exceptionHandler(e.toString());
    }
  }

  /// 保存订阅历史
  /// [subscribe] 订阅历史对象
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  /// 返回保存后的订阅历史对象
  static Future<SubscribeHistory?> saveSubscribeHistory(
    SubscribeHistory subscribe,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 检查是否配置了服务器地址
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      // 发起保存订阅历史的请求
      final response = await dio.post(
        "/subscribe/save",
        data: subscribe.toJson(),
      );
      if (response.statusCode != 200) {
        exceptionHandler.call("保存订阅记录失败");
      }
      successHandler();
      // 解析响应数据
      return SubscribeHistory.fromJson(response.data);
    } catch (e) {
      log("Record saveSubscribeHistory error: $e");
      exceptionHandler(e.toString());
    }
    return null;
  }
}
