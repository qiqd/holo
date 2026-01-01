import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

class AccountApi {
  static Future<void> loginOrRegister({
    bool isRegister = false,
    required String serverUrl,
    required String email,
    required String password,
    required Function() successHandler,
    required Function(String msg) exceptionHandler,
  }) async {
    final dio = Dio(BaseOptions(contentType: "application/json"));
    try {
      if (isRegister) {
        final response = await dio.post(
          "$serverUrl/user/register",
          data: {"password": password, "email": email},
        );
        if (response.statusCode == 200) {
          LocalStore.setEmail(email);
          LocalStore.setServerUrl(serverUrl);
          successHandler.call();
          return;
        }
        exceptionHandler.call("注册失败,${response.statusMessage}");
      } else {
        final response = await dio.post(
          "$serverUrl/user/login",
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
      }
    } catch (e) {
      log("Account login error: $e");
      exceptionHandler.call("登录失败,${e.toString()}");
    }
  }
}
