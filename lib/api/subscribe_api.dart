import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:mobile_holo/entity/subscribe_history.dart';
import 'package:mobile_holo/util/local_store.dart';

class SubscribeApi {
  static String serverUrl = "";
  static String token = "";

  static Dio dio = Dio();
  static void initServer() {
    serverUrl = LocalStore.getServerUrl() ?? "https://localhost:8080";
    token = LocalStore.getToken() ?? "";
    dio.options = BaseOptions(
      headers: {"Authorization": token, "User-Agent": "Holo/client"},
      baseUrl: "$serverUrl/subscribe",
      contentType: "application/json",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  static Future<List<SubscribeHistory>> fetchSubscribeHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return [];
      }
      final response = await dio.get("/query/subscribe");
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
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.get("/query/subscribe/$subId");
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
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/delete/subscribe");
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
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/delete/subscribe/$subId");
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
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return null;
      }
      final response = await dio.post("/save/subscribe", data: subscribe);
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
