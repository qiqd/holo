import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/util/http_util.dart';

/// 设置相关API服务类
/// 提供设置的保存和获取功能
class SettingApi {
  /// 带有拦截器的Dio实例
  static Dio dio = HttpUtil.createDioWithInterceptor();

  /// 保存应用设置
  /// [appSetting] 应用设置对象
  /// [exceptionHandler] 异常回调
  static Future<void> saveSetting(
    AppSetting appSetting,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 发起保存设置的请求
      final response = await dio.post("/setting", data: appSetting.toJson());
      if (response.statusCode != 200) {
        exceptionHandler.call("Update setting failed");
      }
    } catch (e) {
      log("Setting updateSetting error: $e");
    }
  }

  /// 获取应用设置
  /// [exceptionHandler] 异常回调
  /// 返回应用设置对象
  static Future<AppSetting?> fetchSetting(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      // 发起获取设置的请求
      final response = await dio.get("/setting");
      if (response.statusCode != 200) {
        exceptionHandler.call("Fetch setting failed");
      } else {
        // 解析响应数据
        return AppSetting.fromJson(response.data);
      }
    } catch (e) {
      log("Setting fetchSetting error: $e");
      exceptionHandler.call("Fetch setting failed");
    }
    return null;
  }
}
