import 'dart:developer';

import 'package:holo/entity/github_release.dart';
import 'package:holo/util/http_util.dart';

class UpdateApi {
  static const String baseUrl =
      'https://api.github.com/repos/qiqd/holo/releases/latest';

  static Future<GitHubRelease?> getLatestRelease() async {
    try {
      final response = await HttpUtil.createDio().get(baseUrl);
      return GitHubRelease.fromJson(response.data);
    } catch (e) {
      log("UpdateApi.getLatestRelease error: $e");
      return null;
    }
  }
}
