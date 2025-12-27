import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:mobile_holo/util/local_store.dart';

class AccountApi {
  static String serverUrl = "";
  static String token = "";
  static Dio dio = Dio();
  static void initServer() {
    serverUrl = LocalStore.getServerUrl() ?? "https://localhost:8080";
    token = LocalStore.getToken() ?? "";
    dio.options = BaseOptions(
      headers: {"Authorization": token, "User-Agent": "Holo/client"},
      baseUrl: "$serverUrl/user",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  static Future<void> login({
    required String email,
    required String password,
    required Function(String msg) exceptionHandler,
  }) async {
    try {
      final response = await dio.post(
        "/login",
        data: {"password": password, "email": email},
      );
      if (response.statusCode == 200) {
        LocalStore.setToken(response.data as String);
        token = response.data as String;
        dio.options.headers["Authorization"] = token;
        exceptionHandler.call("登录成功");
        LocalStore.setToken(response.data as String);
      }
    } catch (e) {
      log("Account login error: $e");
      exceptionHandler.call(e.toString());
    }
  }

  static Future<void> register({
    required String email,
    required String password,
    required Function(String msg) exceptionHandler,
  }) async {
    try {
      final response = await dio.post(
        "/register",
        data: {"password": password, "email": email},
      );
      if (response.statusCode == 200) {
        LocalStore.setToken(response.data as String);
        token = response.data as String;
        dio.options.headers["Authorization"] = token;
        LocalStore.setToken(response.data as String);
        exceptionHandler.call("注册成功");
      }
    } catch (e) {
      log("Account register error: $e");
      exceptionHandler.call(e.toString());
    }
  }

  static Future<void> update({
    required String email,
    required String password,
    required Function(String msg) exceptionHandler,
  }) async {
    initServer();
    try {
      final response = await dio.put(
        "/update",
        data: {"password": password, "email": email},
      );
      if (response.statusCode != 200) {
        exceptionHandler.call("更新失败");
      }
    } catch (e) {
      log("Account update error: $e");
      exceptionHandler.call(e.toString());
    }
  }
}
