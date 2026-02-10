import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/main.dart';
import 'package:holo/util/check_version.dart';
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

class _SetttingScreenState extends State<SetttingScreen>
    with WidgetsBindingObserver {
  String _version = '';
  String? _email;
  String? _token;
  bool _checkVersioning = false;
  final _appSetting = MyApp.appSetting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVersion();
  }

  @override
  void dispose() {
    LocalStore.saveAppSetting(_appSetting);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // packageInfo.
    setState(() {
      _version = packageInfo.version;
    });
  }

  Future<void> _checkVersion() async {
    setState(() {
      _checkVersioning = true;
    });
    final asset = await CheckVersion.checkVersion();
    if (!mounted) {
      return;
    }
    if (asset != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr("common.new_version")),
          content: Column(
            mainAxisSize: .min,
            children: [
              ListTile(
                title: Text(
                  "${context.tr("common.current_version")}:v${asset.currentVersion}",
                ),
                subtitle: Text(
                  "${context.tr("common.latest_version")}:v${asset.latestVersion}",
                ),
              ),
              Text(asset.summary ?? ""),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(context.tr("common.dialog.cancel")),
            ),
            FilledButton(
              onPressed: () =>
                  launchUrl(Uri.parse(asset.browserDownloadUrl ?? "")),
              child: Text(context.tr("common.dialog.update")),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr("common.no_update"))));
    }
    setState(() {
      _checkVersioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // var isLandscape =
    //     MediaQuery.of(context).orientation == Orientation.landscape;
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
                key: const ValueKey('account_animated_switcher_key'),
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: const ValueKey('account_status_container'),
                  alignment: Alignment.centerLeft,
                  child: (_email != null && _token != null)
                      ? Text(_email!, key: const ValueKey<String>('logged_in'))
                      : Text(
                          'setting.account.logged_out'.tr(),
                          key: const ValueKey<String>('logged_out'),
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
              child: Image.asset('lib/images/launcher_round.png', width: 100),
            ),
            applicationLegalese: 'AGPL-3.0 license',
            aboutBoxChildren: _buildAboutBoxChildren(),
          ),
          ListTile(
            leading: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _checkVersioning
                  ? SizedBox(
                      key: ValueKey('setting.app_info.check_version_loading'),
                      width: 24,
                      height: 24,
                      child: const CircularProgressIndicator(padding: .zero),
                    )
                  : Icon(
                      key: ValueKey('setting.app_info.check_version_icon'),
                      Icons.update_rounded,
                    ),
            ),
            title: Text('setting.app_info.check_version'.tr()),
            onTap: _checkVersion,
          ),
          // 切换语言部分
          _buildSectionHeader('setting.section.language'.tr()),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('setting.language.change'.tr()),
            // subtitle: Text('setting.language.change_description'.tr()),
            trailing: PopupMenuButton(
              child: Icon(Icons.menu_rounded),
              onSelected: (value) {
                context.setLocale(
                  Locale(value.split('-')[0], value.split('-')[1]),
                );
                setState(() {});
                log('Selected language: $value');
              },
              itemBuilder: (content) {
                return [
                  PopupMenuItem(value: 'zh-CN', child: Text('中文简体')),
                  PopupMenuItem(value: 'zh-TW', child: Text('中文繁體')),
                  PopupMenuItem(value: 'en-US', child: Text('English')),
                  PopupMenuItem(value: 'ja-JP', child: Text('日本語')),
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
          if (Platform.isAndroid || Platform.isIOS)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('setting.data_management.clear_cache'.tr()),
              subtitle: Text(
                'setting.data_management.clear_cache_description'.tr(),
              ),
              onTap: () => _clearCache(),
            ),
          // 规则管理部分
          ListTile(
            leading: const Icon(Icons.rule_rounded),
            title: Text('setting.data_management.rule_manager'.tr()),
            subtitle: Text(
              'setting.data_management.rule_manager_description'.tr(),
            ),
            onTap: () => context.push('/rule_manager'),
          ),

          // 外观设置部分
          _buildSectionHeader('setting.section.appearance'.tr()),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text('setting.appearance.theme_mode'.tr()),
            subtitle: Text(_getThemeModeText()),
            onTap: () => _showThemeModeDialog(),
          ),
          SwitchListTile(
            secondary: Icon(Icons.colorize_rounded),
            value: MyApp.useSystemColorNotifier.value,
            title: Text('setting.appearance.use_system_color'.tr()),
            subtitle: Text(
              'setting.appearance.use_system_color_description'.tr(),
            ),
            onChanged: (value) => setState(() {
              _appSetting.useSystemColor = value;
              LocalStore.saveAppSetting(_appSetting);
            }),
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

  List<Widget> _buildAboutBoxChildren() {
    return [
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
      //每日一言
      // Text(
      //   'setting.app_info.daily_sentence'.tr(),
      //   style: const TextStyle(fontWeight: FontWeight.bold),
      // ),
      // InkWell(
      //   child: const Text('sekaiai.github.io'),
      //   onTap: () {
      //     launchUrl(Uri.parse('https://github.com/sekaiai/sekaiai.github.io'));
      //   },
      // ),
    ];
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
                DefaultCacheManager().emptyCache();
                log('应用缓存已清除');
                Navigator.pop(context);
              },
              child: Text('setting.data_management.clear_dialog_confirm'.tr()),
            ),
          ],
        ),
      );
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
              MyApp.themeNotifier.value = currentTheme ?? ThemeMode.system;
              _appSetting.themeMode = currentTheme?.index ?? 0;
              LocalStore.saveAppSetting(_appSetting);
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
