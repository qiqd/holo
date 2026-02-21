import 'dart:developer';

import 'package:holo/entity/github_release.dart';
import 'package:holo/util/http_util.dart';

/// 更新相关API服务类
/// 提供获取最新版本信息的功能
class UpdateApi {
  /// GitHub API 基础URL
  static const String baseUrl =
      'https://api.github.com/repos/qiqd/holo/releases/latest';

  /// 获取最新版本信息
  /// 返回GitHub发布信息对象
  static Future<GitHubRelease?> getLatestRelease() async {
    try {
      // 发起获取最新版本的请求
      final response = await HttpUtil.createDio().get(baseUrl);
      // 解析响应数据
      return GitHubRelease.fromJson(response.data);
    } catch (e) {
      log("UpdateApi.getLatestRelease error: $e");
      return null;
    }
  }
}
