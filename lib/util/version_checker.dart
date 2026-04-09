import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/update_api.dart';
import 'package:holo/entity/github_release.dart';
import 'package:logger/web.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 版本检查类
/// 用于检查应用程序的版本更新，获取最新版本信息并提示用户更新
class VersionChecker {
  static const MethodChannel _channel = MethodChannel('abi_detector');
  static final Logger _logger = Logger();

  /// 获取设备ABI信息
  static Future<String?> getDeviceAbi() async {
    try {
      final String? abi = await _channel.invokeMethod('getDeviceAbi');
      _logger.i('Device ABI: $abi');
      return abi;
    } on PlatformException catch (e) {
      _logger.e('Failed to get device ABI: ${e.message}');
      return null;
    }
  }

  /// 获取最新版本信息
  /// 返回简化的 GitHub 资产信息，若没有新版本则返回 null
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
      final abi = await getDeviceAbi();
      final androidAsset = latestRelease.assets
          ?.where(
            (element) =>
                element.name?.contains('.apk') == true &&
                element.name?.contains(abi ?? 'release') == true,
          )
          .firstOrNull;

      simpleGitHubAsset.browserDownloadUrl = androidAsset?.browserDownloadUrl;
      return androidAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isIOS) {
      final iosAsset = latestRelease.assets
          ?.where((element) => element.name?.contains('.ipa') == true)
          .firstOrNull;
      simpleGitHubAsset.browserDownloadUrl = iosAsset?.browserDownloadUrl;
      return iosAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isWindows) {
      final windowsAsset = latestRelease.assets
          ?.where((element) => element.name?.contains('windows') == true)
          .firstOrNull;
      simpleGitHubAsset.browserDownloadUrl = windowsAsset?.browserDownloadUrl;
      return windowsAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isMacOS) {
      final macosAsset = latestRelease.assets
          ?.where((element) => element.name?.contains('macos') == true)
          .firstOrNull;
      simpleGitHubAsset.browserDownloadUrl = macosAsset?.browserDownloadUrl;
      return macosAsset == null ? null : simpleGitHubAsset;
    } else if (Platform.isLinux) {
      final linuxAsset = latestRelease.assets
          ?.where((element) => element.name?.contains('linux') == true)
          .firstOrNull;
      simpleGitHubAsset.browserDownloadUrl = linuxAsset?.browserDownloadUrl;
      return linuxAsset == null ? null : simpleGitHubAsset;
    }
    return null;
  }

  /// 检查版本更新 ，如果自动检查更新为false，则不检查
  /// [context]: 上下文
  /// 如果有新版本，显示更新对话框
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
                  subtitle: Text(
                    "${context.tr("common.current_version")}:v${asset.currentVersion}",
                  ),
                  title: Text(
                    "${context.tr("common.latest_version")}:v${asset.latestVersion}",
                  ),
                ),
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
