import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

class SubscribeApi {
  static Dio dio = HttpUtil.createDioWithInterceptor();
  static Future<List<SubscribeHistory>> fetchSubscribeHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return [];
      }
      final response = await dio.get("/subscribe/query");
      if (response.statusCode == 200) {
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

  static Future<SubscribeHistory?> fetchSubscribeHistoryBySubId(
    int subId,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.get("/subscribe/query/$subId");
      if (response.statusCode == 200) {
        return SubscribeHistory.fromJson(response.data);
      }
      return null;
    } catch (e) {
      log("Record getSubscribeHistory error: $e");
      exceptionHandler(e.toString());
      return null;
    }
  }

  static Future<void> deleteAllSubscribeRecord(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return;
      }
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

  static Future<void> deleteSubscribeRecordBySubId(
    int subId,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return;
      }
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

  static Future<SubscribeHistory?> saveSubscribeHistory(
    SubscribeHistory subscribe,
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.post(
        "/subscribe/save",
        data: subscribe.toJson(),
      );
      if (response.statusCode != 200) {
        exceptionHandler.call("保存订阅记录失败");
      }
      successHandler();
      return SubscribeHistory.fromJson(response.data);
    } catch (e) {
      log("Record saveSubscribeHistory error: $e");
      exceptionHandler(e.toString());
    }
    return null;
  }
}
