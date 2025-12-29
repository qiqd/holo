import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:mobile_holo/entity/history.dart';
import 'package:mobile_holo/util/local_store.dart';

class RecordApi {
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

  static Future<List<History>> fetchAllHistory(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      final response = await dio.get("/query");
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((item) => History.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      log("Record getHistory error: $e");
      exceptionHandler(e.toString());
      return [];
    }
  }

  static Future<void> deleteAllRecord(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      if (LocalStore.getServerUrl() == null) {
        return;
      }
      final response = await dio.delete("/delete/all");
      if (response.statusCode != 200) {
        exceptionHandler.call("删除所有记录失败");
      } else {
        successHandler();
      }
    } catch (e) {
      log("Record deleteAllRecord error: $e");
      exceptionHandler(e.toString());
    }
  }

  static Future<void> saveAllRecord(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      initServer();
      var all = LocalStore.gerAllHistory();
      final response = await dio.post("/save/batch", data: all);
      if (response.statusCode != 200) {
        exceptionHandler.call("保存所有记录失败");
      }
      successHandler.call();
    } catch (e) {
      log("Record saveAllRecord error: $e");
      exceptionHandler(e.toString());
    }
  }
}
