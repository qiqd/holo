import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:holo/entity/user.dart';
import 'package:holo/entity/user_playback.dart';
import 'package:holo/entity/user_setting.dart';
import 'package:holo/entity/user_subscribe.dart';
import 'package:holo/util/logger_util.dart';
import 'package:logger/logger.dart';

class WebDAV {
  static const String _appDBPath = "holo/";
  static const String _settingPath = "holo/user_setting.json";
  static const String _subscribePath = "holo/user_subscribe.json";
  static const String _playbackPath = "holo/user_playback.json";
  static final Logger _logger = LoggerUtil.logger;
  static Dio? _dio;
  static void init(User? user) {
    if (user == null) {
      return;
    }
    _dio = Dio()
      ..options.baseUrl = user.serverUrl
      ..options.contentType = "application/json"
      ..options.headers["User-Agent"] = "Holo/client"
      ..options.headers["Authorization"] =
          "Basic ${base64.encode(utf8.encode("${user.email}:${user.secret}"))}";

    folderChecker();
  }

  ///webDAV登录
  static Future<bool> login({
    required String url,
    required String email,
    required String secret,
    void Function(String message)? onError,
  }) async {
    final dio = Dio();
    final basicAuth = "Basic ${base64.encode(utf8.encode("$email:$secret"))}";
    try {
      var request = await dio.request<String>(
        url,
        options: Options(
          method: "PROPFIND",
          headers: {
            "Content-Type": "application/json",
            "Authorization": basicAuth,
          },
        ),
      );

      return (request.statusCode ?? 500) ~/ 100 == 2;
    } catch (e) {
      onError?.call(e.toString());
      _logger.e(e.toString());
      return false;
    }
  }

  /// 检查文件夹是否存在，不存在就创建
  static Future<void> folderChecker() async {
    if (_dio == null) {
      return;
    }
    try {
      final res = await _dio!.request<void>(
        _appDBPath,
        options: Options(method: "PROPFIND"),
      );

      //目录已经存在
      if (res.statusCode == 207) {
        return;
      }
    } catch (e) {
      _logger.e(e.toString());
      //创建用来保存数据的目录
      await _dio?.request(_appDBPath, options: Options(method: "MKCOL"));
    }
  }

  static Future<List<UserSubscribe>> fetchUserSubscribe() async {
    try {
      final subscribe = await _dio?.get(_subscribePath);
      return (json.decode(subscribe?.data) as List)
          .map((e) => UserSubscribe.fromJson(e))
          .toList();
    } catch (e) {
      _logger.e(e.toString());
      return [];
    }
  }

  static Future<List<UserPlayback>> fetchUserPlayback() async {
    try {
      final playback = await _dio?.get(_playbackPath);
      return (json.decode(playback?.data) as List)
          .map((e) => UserPlayback.fromJson(e))
          .toList();
    } catch (e) {
      _logger.e(e.toString());
      return [];
    }
  }

  static Future<UserSetting?> fetchUserSetting() async {
    try {
      final setting = await _dio?.get(_settingPath);
      return UserSetting.fromJson(json.decode(setting?.data));
    } catch (e) {
      _logger.e(e.toString());
      return null;
    }
  }

  static Future<bool> syncUserSetting(UserSetting setting) async {
    try {
      final res = await _dio?.put<void>(
        _settingPath,
        data: setting.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      return (res?.statusCode ?? 500) ~/ 100 == 2;
    } catch (e) {
      _logger.e(e.toString());
      return false;
    }
  }

  static Future<bool> syncUserSubscribe(
    List<UserSubscribe> subscribeList,
  ) async {
    try {
      final res = await _dio?.put<void>(
        _subscribePath,
        data: subscribeList.map((e) => e.toJson()).toList(),
        options: Options(contentType: Headers.jsonContentType),
      );
      return res?.statusCode == 204;
    } catch (e) {
      _logger.e(e.toString());
      return false;
    }
  }

  static Future<bool> syncUserPlayback(List<UserPlayback> playbackList) async {
    try {
      final res = await _dio?.put<void>(
        _playbackPath,
        data: playbackList.map((e) => e.toJson()).toList(),
        options: Options(contentType: Headers.jsonContentType),
      );
      return res?.statusCode == 204;
    } catch (e) {
      _logger.e(e.toString());
      return false;
    }
  }
}
