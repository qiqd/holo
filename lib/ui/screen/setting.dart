import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/main.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:holo/util/local_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:easy_localization/easy_localization.dart';

class SetttingScreen extends StatefulWidget {
  const SetttingScreen({super.key});

  @override
  State<SetttingScreen> createState() => _SetttingScreenState();
}

class _SetttingScreenState extends State<SetttingScreen> {
  String _version = '';
  String? _email;
  String? _token;
  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // packageInfo.
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('setting.title'.tr())),
      body: ListView(
        children: [
          _buildSectionHeader('setting.section.account_status'.tr()),
          VisibilityDetector(
            key: const Key('account_info_section'),
            child: ListTile(
              leading: const Icon(Icons.account_circle_rounded),
              title: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _email != null && _token != null
                        ? _email!
                        : 'setting.account.logged_out'.tr(),
                    key: ValueKey<String>(
                      _email != null && _token != null
                          ? _email!
                          : 'setting.account.logged_out'.tr(),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              onTap: () {
                if (_email == null || _token == null) {
                  context.push('/sign');
                }
              },
            ),
            onVisibilityChanged: (visibilityInfo) {
              // log('Visibility: ${visibilityInfo.visibleFraction}');
              if (visibilityInfo.visibleFraction > 0) {
                setState(() {
                  _email = LocalStore.getEmail();
                  _token = LocalStore.getToken();
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: Text('setting.account.logout'.tr()),
            subtitle: Text('setting.account.logout_description'.tr()),
            onTap: () => _showSignoutAccountDialog(),
          ),
          // 应用信息部分
          _buildSectionHeader('setting.section.app_info'.tr()),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: 'Holo',
            applicationVersion: 'v$_version',
            applicationIcon: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('lib/images/launcher.png', width: 100),
            ),
            applicationLegalese: 'AGPL-3.0 license',
            aboutBoxChildren: [
              Text('setting.app_description'.tr()),
              //番剧元数据
              Text(
                'setting.app_info.metadata_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                child: const Text('Bangumi 番组计划'),
                onTap: () {
                  launchUrl(Uri.parse('https://bangumi.tv'));
                },
              ),
              //弹幕提供
              Text(
                'setting.app_info.danmaku_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                child: const Text('LogVar 弹幕'),
                onTap: () {
                  launchUrl(Uri.parse('https://danmuapi.vercel.app'));
                },
              ),
              //番剧图片搜索
              Text(
                'setting.app_info.anime_image_search'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                child: const Text('AnimeTrace'),
                onTap: () {
                  launchUrl(Uri.parse('https://ai.animedb.cn'));
                },
              ),
            ],
          ),

          // 切换语言部分
          _buildSectionHeader('setting.section.language'.tr()),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('setting.language.change'.tr()),
            trailing: PopupMenuButton(
              itemBuilder: (content) {
                return [
                  PopupMenuItem(
                    value: 'zh-CN',
                    child: Text('中文简体'),
                    onTap: () {
                      context.setLocale(Locale('zh', 'CN'));
                      setState(() {});
                    },
                  ),
                  PopupMenuItem(
                    value: 'zh-TW',
                    child: Text('中文繁體'),
                    onTap: () {
                      context.setLocale(Locale('zh', 'TW'));
                      setState(() {});
                    },
                  ),
                  PopupMenuItem(
                    value: 'en-US',
                    child: Text('English'),
                    onTap: () {
                      context.setLocale(Locale('en', 'US'));
                      setState(() {});
                    },
                  ),

                  PopupMenuItem(
                    value: 'ja-JP',
                    child: Text('日本語'),
                    onTap: () {
                      context.setLocale(Locale('ja', 'JP'));
                      setState(() {});
                    },
                  ),
                ];
              },
            ),
          ),

          // 数据管理部分
          _buildSectionHeader('setting.section.data_management'.tr()),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text('setting.data_management.clear_playback_history'.tr()),
            subtitle: Text(
              'setting.data_management.clear_playback_history_description'.tr(),
            ),
            onTap: () => _clearHistory(
              true,
              () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('setting.data_management.cloud_success'.tr()),
                ),
              ),
              (msg) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'setting.data_management.cloud_failed'.tr() + msg,
                  ),
                ),
              ),
              () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('setting.data_management.local_success'.tr()),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: Text('setting.data_management.clear_subscribe_history'.tr()),
            subtitle: Text(
              'setting.data_management.clear_subscribe_history_description'
                  .tr(),
            ),
            onTap: () => _clearHistory(
              false,
              () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('setting.data_management.cloud_success'.tr()),
                ),
              ),
              (msg) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'setting.data_management.cloud_failed'.tr() + msg,
                  ),
                ),
              ),
              () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('setting.data_management.local_success'.tr()),
                ),
              ),
            ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.favorite_outline),
          //   title: const Text('清除收藏'),
          //   subtitle: const Text('取消所有收藏'),
          //   onTap: () => _clearFavorites(),
          // ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text('setting.data_management.clear_cache'.tr()),
            subtitle: Text(
              'setting.data_management.clear_cache_description'.tr(),
            ),
            onTap: () => _clearCache(),
          ),

          // 外观设置部分
          _buildSectionHeader('setting.section.appearance'.tr()),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text('setting.appearance.theme_mode'.tr()),
            subtitle: Text(_getThemeModeText()),
            onTap: () => _showThemeModeDialog(),
          ),

          // 开源项目部分
          _buildSectionHeader('setting.section.open_source'.tr()),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text('setting.open_source.source_code'.tr()),
            subtitle: Text('setting.open_source.source_code_description'.tr()),
            onTap: () => _openGitHub('https://github.com/qiqd/holo'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text('setting.open_source.report_issue'.tr()),
            subtitle: Text('setting.open_source.report_issue_description'.tr()),
            onTap: () => _openGitHub('https://github.com/qiqd/holo/issues'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text('setting.open_source.star_project'.tr()),
            subtitle: Text('setting.open_source.star_project_description'.tr()),
            onTap: () => _openGitHub('https://github.com/qiqd/holo'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('setting.app_info.about_dialog_title'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('setting.app_info.about_dialog_content'.tr()),
              const SizedBox(height: 16),
              Text(
                'setting.app_info.license_title'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('AGPL-3.0 license'),
              const SizedBox(height: 8),
              Text(
                'setting.app_info.metadata_title'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Bangumi 番组计划'),
              Text(
                'setting.app_info.danmaku_title'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('LogVar 弹幕'),
              Text(
                'setting.app_info.libraries_title'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• flutter - BSD License'),
              const Text('• dio - MIT License'),
              const Text('• shared_preferences - BSD License'),
              const Text('• url_launcher - BSD License'),
              const Text('• package_info_plus - BSD License'),
              const Text('• path_provider - BSD License'),
              const Text('• video_player - BSD License'),
              const Text('• go_router - BSD License'),
              const Text('• screen_brightness - MIT License'),
              const Text('• volume_controller - MIT License'),
              const Text('• simple_gesture_detector - MIT License'),
              const Text('• cached_network_image - MIT License'),
              const Text('• flutter_svg - MIT License'),
              const Text('• provider - MIT License'),
              const Text('• flutter_localizations - BSD License'),
              const Text('• intl - BSD License'),
              const Text('• crypto - BSD License'),
              const Text('• convert - BSD License'),
              const Text('• collection - BSD License'),
              const Text('• typed_data - BSD License'),
              const Text('• meta - BSD License'),
              const Text('• vector_math - BSD License'),
              const Text('• flutter_test - BSD License'),
              const Text('• flutter_lints - BSD License'),
              const Text('• build_runner - BSD License'),
              const Text('• flutter_launcher_icons - MIT License'),
              const Text('• html - BSD License'),
              const Text('• pointycastle - MIT License'),
              const Text('• encrypt - MIT License'),
              const Text('• canvas_danmaku - MIT License'),
              const Text('• visibility_detector - BSD License'),
              const Text('• easy_localization - MIT License'),
              const Text('• shimmer - BSD-3-Clause License'),
              const Text('• flutter_dotenv - MIT License'),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('setting.data_management.clear_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _clearHistory(
    bool isPlayback,
    Function onCloudSuccess,
    Function(dynamic msg) onCloudfaild,
    Function onLocalSuccess,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('setting.data_management.clear_dialog_title'.tr()),
        content: Text(
          isPlayback
              ? 'setting.data_management.clear_dialog_content_playback'.tr()
              : 'setting.data_management.clear_dialog_content_subscribe'.tr(),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('setting.data_management.clear_dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (isPlayback) {
                PlayBackApi.deleteAllPlaybackRecord(() {
                  onCloudSuccess();
                }, (e) => onCloudfaild(e));
              } else {
                SubscribeApi.deleteAllSubscribeRecord(() {
                  onCloudSuccess();
                }, (e) => onCloudfaild(e));
              }
              LocalStore.clearHistory(clearPlayback: isPlayback);
              onLocalSuccess();
            },
            child: Text('setting.data_management.clear_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('setting.data_management.clear_dialog_title'.tr()),
          content: Text('setting.data_management.cache_dialog_content'.tr()),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('setting.data_management.clear_dialog_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () {
                // 清除缓存逻辑
                // Navigator.pop(context);
                DefaultCacheManager().emptyCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('setting.data_management.cache_success'.tr()),
                  ),
                );
              },
              child: Text('setting.data_management.clear_dialog_confirm'.tr()),
            ),
          ],
        ),
      );
      log('应用缓存已清除');
    } catch (e) {
      log('清除缓存失败: $e');
    }
  }

  void _openGitHub(String link) async {
    try {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // 使用外部浏览器打开
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('setting.open_source.source_code_description'.tr()),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'setting.open_source.source_code_description'.tr()}: $e',
            ),
          ),
        );
      }
    }
  }

  String _getThemeModeText() {
    final themeMode = MyApp.themeNotifier.value;
    switch (themeMode) {
      case ThemeMode.system:
        return 'setting.appearance.theme_mode_system'.tr();
      case ThemeMode.light:
        return 'setting.appearance.theme_mode_light'.tr();
      case ThemeMode.dark:
        return 'setting.appearance.theme_mode_dark'.tr();
    }
  }

  void _showThemeModeDialog() {
    ThemeMode? currentTheme = MyApp.themeNotifier.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('setting.appearance.theme_dialog_title'.tr()),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('setting.appearance.theme_mode_system'.tr()),
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      setState(() {
                        currentTheme = value;
                      });
                    }
                  },
                ),

                RadioListTile<ThemeMode>(
                  title: Text('setting.appearance.theme_mode_dark'.tr()),
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      setState(() {
                        currentTheme = value;
                      });
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text('setting.appearance.theme_mode_light'.tr()),
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      setState(() {
                        currentTheme = value;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('setting.appearance.theme_dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              MyApp.themeNotifier.value = currentTheme!;
              LocalStore.setString('theme_mode', currentTheme.toString());
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('setting.appearance.theme_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSignoutAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('setting.account.signout_dialog_title'.tr()),
        content: Text('setting.account.signout_dialog_content'.tr()),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('setting.account.signout_dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _email = null;
              });
              LocalStore.removeLocalAccount();
              Navigator.pop(context);
            },
            child: Text('setting.account.signout_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }
}
