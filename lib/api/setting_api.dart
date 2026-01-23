import 'dart:convert';
import 'dart:developer';

import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:dio/dio.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

class SettingApi {
  static Dio dio = HttpUtil.createDioWithInterceptor();
  static Future<void> updateSetting(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      var useSystemColor = LocalStore.getUseSystemColor();
      var danmuOption = LocalStore.getDanmakuOption();
      var themeMode = LocalStore.getString('theme_mode');
      Map<String, dynamic>? danmakuOptionMap;
      var filterWord = danmuOption?['filterWord'] ?? '';
      if (danmuOption != null && danmuOption['option'] != null) {
        DanmakuOption option = danmuOption['option'];
        danmakuOptionMap = {
          "opacity": option.opacity,
          "area": option.area,
          "fontSize": option.fontSize,
          "hideTop": option.hideTop,
          "hideBottom": option.hideBottom,
          "hideScroll": option.hideScroll,
          "massiveMode": option.massiveMode,
        };
      } else {
        DanmakuOption defaultOption = DanmakuOption();
        danmakuOptionMap = {
          "opacity": defaultOption.opacity,
          "area": defaultOption.area,
          "fontSize": defaultOption.fontSize,
          "hideTop": defaultOption.hideTop,
          "hideBottom": defaultOption.hideBottom,
          "hideScroll": defaultOption.hideScroll,
          "massiveMode": defaultOption.massiveMode,
        };
      }
      final response = await dio.post(
        "/setting",
        data: {
          'filterWord': filterWord,
          "useSystemColor": useSystemColor,
          "danmakuOption": danmakuOptionMap,
          "themeMode": themeMode,
        },
      );
      if (response.statusCode != 200) {
        exceptionHandler.call("Update setting failed");
      } else {
        successHandler();
      }
    } catch (e) {
      log("Setting updateSetting error: $e");
    }
  }

  static Future<void> fetchSetting(
    Function() successHandler,
    Function(String msg) exceptionHandler,
  ) async {
    try {
      final response = await dio.get("/setting");
      if (response.statusCode != 200) {
        exceptionHandler.call("Fetch setting failed");
      } else {
        var data = response.data as Map<String, dynamic>;
        LocalStore.setUseSystemColor(data['useSystemColor']);
        LocalStore.saveDanmakuOption(
          data['danmuOption'],
          filter: data['filterWord'] ?? '',
        );
        LocalStore.setString('theme_mode', data['themeMode']);
      }
    } catch (e) {
      log("Setting fetchSetting error: $e");
    }
  }
}
