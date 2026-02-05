import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:holo/api/update_api.dart';
import 'package:holo/entity/github_release.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CheckVersion {
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static Future<SimpleGitHubAsset?> checkVersion() async {
    final latestRelease = await UpdateApi.getLatestRelease();
    if (latestRelease == null) {
      return null;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final versionCode = packageInfo.version.split('.').toList();

    final latestVersionCode = latestRelease.tagName!.split('.').toList();
    final isNewVersion = latestVersionCode.asMap().entries.any((element) {
      return int.parse(element.value) > int.parse(versionCode[element.key]);
    });
    if (!isNewVersion) {
      return null;
    }
    SimpleGitHubAsset simpleGitHubAsset = SimpleGitHubAsset(
      currentVersion: packageInfo.version,
      latestVersion: latestRelease.tagName,
      summary: latestRelease.body,
    );
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final androidAsset = latestRelease.assets?.firstWhere(
        (element) =>
            element.name?.contains('.apk') == true &&
            element.name?.contains(androidInfo.supportedAbis.first) == true,
      );
      simpleGitHubAsset.browserDownloadUrl = androidAsset?.browserDownloadUrl;
      return androidAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isIOS) {
      final iosAsset = latestRelease.assets?.firstWhere(
        (element) => element.name?.contains('.ipa') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = iosAsset?.browserDownloadUrl;
      return iosAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isWindows) {
      final windowsAsset = latestRelease.assets?.firstWhere(
        (element) => element.name?.contains('windows-app') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = windowsAsset?.browserDownloadUrl;
      return windowsAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isMacOS) {
      final macosAsset = latestRelease.assets?.firstWhere(
        (element) => element.name?.contains('macos-app') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = macosAsset?.browserDownloadUrl;
      return macosAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isLinux) {
      final linuxAsset = latestRelease.assets?.firstWhere(
        (element) => element.name?.contains('linux-app') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = linuxAsset?.browserDownloadUrl;
      return linuxAsset == null ? null : simpleGitHubAsset;
    }
    return null;
  }
}
