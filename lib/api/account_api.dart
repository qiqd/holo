import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:mobile_holo/util/local_store.dart';

class AccountApi {
  static Future<void> login({
    required String serverUrl,
    required String email,
    required String password,
    required Function() successHandler,
    required Function(String msg) exceptionHandler,
  }) async {
    try {
      final dio = Dio();
      dio.options = BaseOptions(
        headers: {"User-Agent": "Holo/client"},
        baseUrl: "$serverUrl/user",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );
      final response = await dio.post(
        "/login",
        data: {"password": password, "email": email},
      );
      if (response.statusCode == 200) {
        LocalStore.setToken(response.data as String);
        final token = response.data as String;
        LocalStore.setEmail(email);
        LocalStore.setToken(token);
        LocalStore.setServerUrl(serverUrl);
        successHandler.call();
        return;
      }
      exceptionHandler.call("登录失败,${response.statusMessage}");
    } catch (e) {
      log("Account login error: $e");
      exceptionHandler.call("登录失败,${e.toString()}");
    }
  }
}
