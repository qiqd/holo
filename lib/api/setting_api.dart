import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/util/http_util.dart';

class SettingApi {
  static Dio dio = HttpUtil.createDioWithInterceptor();
  static Future<void> saveSetting(
    AppSetting appSetting,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      final response = await dio.post("/setting", data: appSetting.toJson());
      if (response.statusCode != 200) {
        exceptionHandler.call("Update setting failed");
      }
    } catch (e) {
      log("Setting updateSetting error: $e");
    }
  }

  static Future<AppSetting?> fetchSetting(
    Function(String msg) exceptionHandler,
  ) async {
    try {
      final response = await dio.get("/setting");
      if (response.statusCode != 200) {
        exceptionHandler.call("Fetch setting failed");
      } else {
        return AppSetting.fromJson(json.decode(response.data));
      }
    } catch (e) {
      log("Setting fetchSetting error: $e");
      exceptionHandler.call("Fetch setting failed");
    }
    return null;
  }
}
