import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:holo/entity/user.dart';
import 'package:holo/util/hive_util.dart';
import 'package:logger/logger.dart';

class WebDAV {
  static const String _appDBPath = "holo/";
  static const String _settingPath = "holo/user_setting.hive";
  static const String _subscribePath = "holo/user_subscribe.hive";
  static const String _playbackPath = "holo/user_playback.hive";
  static final Logger _logger = Logger();
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
      final res = await _dio!.request<String>(
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

  /// 从webDAV获取数据
  static Future<bool?> fetchData() async {
    if (HiveUtil.user == null) {
      return null;
    }
    try {
      await HiveUtil.closeHive();
      folderChecker();
      if (_dio == null) {
        return null;
      }
      final future1 = _dio!.download(
        _subscribePath,
        HiveUtil.getUserSubscribePath(),
      );
      final future2 = _dio!.download(
        _playbackPath,
        HiveUtil.getUserPlaybackPath(),
      );
      final future3 = _dio!.download(
        _settingPath,
        HiveUtil.getUserSettingPath(),
      );
      await Future.wait([future1, future2, future3]);
      await HiveUtil.initHive();
      return true;
    } catch (e) {
      _logger.e(e.toString());
      return false;
    }
  }

  /// 同步数据到webDAV
  /// [isCommon] 是否是公共数据
  static Future<bool> syncData(bool isCommon) async {
    try {
      final future1 = uploadFile(
        filePath: isCommon
            ? HiveUtil.getCommonUserSettingPath()
            : HiveUtil.getUserSettingPath(),
        targetPath: _settingPath,
      );
      final future2 = uploadFile(
        filePath: isCommon
            ? HiveUtil.getCommonUserSubscribePath()
            : HiveUtil.getUserSubscribePath(),
        targetPath: _subscribePath,
      );
      final future3 = uploadFile(
        filePath: isCommon
            ? HiveUtil.getCommonUserPlaybackPath()
            : HiveUtil.getUserPlaybackPath(),
        targetPath: _playbackPath,
      );
      await Future.wait([future1, future2, future3]);
      return true;
    } catch (e) {
      _logger.e(e.toString());
      return false;
    }
  }

  static Future<bool> uploadFile({
    required String filePath,
    required String targetPath,
  }) async {
    if (_dio == null) {
      return false;
    }
    try {
      final res = await _dio!.request<void>(
        targetPath,
        data: File(filePath).openRead(),
        options: Options(method: "PUT"),
      );
      return res.statusCode == 204;
    } catch (e) {
      _logger.e(e.toString());
      return false;
    }
  }
}
