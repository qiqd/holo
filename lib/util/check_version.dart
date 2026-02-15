import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/update_api.dart';
import 'package:holo/entity/github_release.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckVersion {
  static String matchName = '';
  static String supportedAbi = '';
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static Future<SimpleGitHubAsset?> _fetchLatestRelease() async {
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
      releaseLog: latestRelease.body,
    );
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;

      supportedAbi = androidInfo.supportedAbis.join(',');
      final androidAsset = latestRelease.assets?.firstWhere(
        (element) =>
            element.name?.contains('.apk') == true &&
            element.name?.contains(androidInfo.supportedAbis.first) == true,
      );
      matchName = androidAsset?.name ?? '';
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
        (element) => element.name?.contains('windows') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = windowsAsset?.browserDownloadUrl;
      return windowsAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isMacOS) {
      final macosAsset = latestRelease.assets?.firstWhere(
        (element) => element.name?.contains('macos') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = macosAsset?.browserDownloadUrl;
      return macosAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isLinux) {
      final linuxAsset = latestRelease.assets?.firstWhere(
        (element) => element.name?.contains('linux') == true,
      );
      simpleGitHubAsset.browserDownloadUrl = linuxAsset?.browserDownloadUrl;
      return linuxAsset == null ? null : simpleGitHubAsset;
    }
    return null;
  }

  static Future<void> checkVersion(BuildContext context) async {
    final asset = await _fetchLatestRelease();
    if (asset != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr("common.new_version")),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    "${context.tr("common.current_version")}:v${asset.currentVersion}",
                  ),
                  subtitle: Text(
                    "${context.tr("common.latest_version")}:v${asset.latestVersion}",
                  ),
                ),
                Text('device abi: $supportedAbi'),
                Text('match name: $matchName'),
                Text('download_url: ${asset.browserDownloadUrl ?? ""}'),
                Text(asset.releaseLog ?? ""),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(context.tr("common.dialog.cancel")),
            ),
            FilledButton(
              onPressed: () async {
                await launchUrl(
                  Uri.parse(asset.browserDownloadUrl ?? ""),
                  mode: LaunchMode.externalApplication,
                );
                if (context.mounted) {
                  context.pop();
                }
              },

              child: Text(context.tr("common.dialog.update")),
            ),
          ],
        ),
      );
    }
  }
}
