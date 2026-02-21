import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:holo/util/local_store.dart';

/// 账户相关API服务类
/// 提供登录和注册功能
class AccountApi {
  /// 登录或注册方法
  /// [isRegister] 是否为注册操作
  /// [serverUrl] 服务器地址
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// [successHandler] 成功回调
  /// [exceptionHandler] 异常回调
  static Future<void> loginOrRegister({
    bool isRegister = false,
    required String serverUrl,
    required String email,
    required String password,
    required Function() successHandler,
    required Function(String msg) exceptionHandler,
  }) async {
    // 创建Dio实例
    final dio = Dio(BaseOptions(contentType: "application/json"));
    try {
      if (isRegister) {
        // 注册请求
        final response = await dio.post(
          "$serverUrl/user/register",
          data: {"password": password, "email": email},
        );
        if (response.statusCode == 200) {
          // 保存邮箱和服务器地址
          LocalStore.setEmail(email);
          LocalStore.setServerUrl(serverUrl);
          // 调用成功回调
          successHandler.call();
          return;
        }
        // 注册失败
        exceptionHandler.call("注册失败,${response.statusMessage}");
      } else {
        // 登录请求
        final response = await dio.post(
          "$serverUrl/user/login",
          data: {"password": password, "email": email},
        );
        if (response.statusCode == 200) {
          // 获取并保存token
          final token = response.data as String;
          LocalStore.setToken(token);
          LocalStore.setEmail(email);
          LocalStore.setServerUrl(serverUrl);
          // 调用成功回调
          successHandler.call();
          return;
        }
        // 登录失败
        exceptionHandler.call("登录失败,${response.statusMessage}");
      }
    } catch (e) {
      // 捕获异常
      log("Account login error: $e");
      exceptionHandler.call("登录失败,${e.toString()}");
    }
  }
}
