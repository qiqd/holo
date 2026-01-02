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
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionHeader('账户状态'),
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
                    _email != null && _token != null ? _email! : '未登录',
                    key: ValueKey<String>(
                      _email != null && _token != null ? _email! : '未登录',
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
              log('Visibility: ${visibilityInfo.visibleFraction}');
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
            title: const Text('退出账号'),
            subtitle: const Text('退出当前账号,但是本地历史记录数据不会删除'),
            onTap: () => _showSignoutAccountDialog(),
          ),
          // 应用信息部分
          _buildSectionHeader('应用信息'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于应用'),
            subtitle: Text('版本 $_version'),
            onTap: () => _showAboutDialog(),
          ),

          // 数据管理部分
          _buildSectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('清除观看历史'),
            subtitle: const Text('删除所有观看历史记录,包括云端'),
            onTap: () => _clearHistory(
              true,
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('云端历史记录已清除'))),
              (msg) => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('云端历史记录清除失败$msg'))),
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('本地历史已清除'))),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: const Text('清除订阅历史'),
            subtitle: const Text('删除所有订阅记录,包括云端'),
            onTap: () => _clearHistory(
              false,
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('云端历史记录已清除'))),
              (msg) => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('云端历史记录清除失败$msg'))),
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('本地历史已清除'))),
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
            title: const Text('清除缓存'),
            subtitle: const Text('清理应用缓存数据'),
            onTap: () => _clearCache(),
          ),

          // 外观设置部分
          _buildSectionHeader('外观设置'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(_getThemeModeText()),
            onTap: () => _showThemeModeDialog(),
          ),

          // 开源项目部分
          _buildSectionHeader('开源项目'),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('源代码'),
            subtitle: const Text('在GitHub上查看源代码'),
            onTap: () => _openGitHub('https://github.com/qiqd/holo'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('报告问题'),
            subtitle: const Text('提交Bug或功能建议'),
            onTap: () => _openGitHub('https://github.com/qiqd/holo/issues'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('给项目点赞'),
            subtitle: const Text('在GitHub上为项目点星'),
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
        title: const Text('关于 Holo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('一个开源的追番APP！'),
              const SizedBox(height: 16),
              const Text('开源协议', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('AGPL-3.0 license'),
              const SizedBox(height: 8),
              const Text(
                '番剧元信息',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Bangumi 番组计划'),
              const Text('第三方库', style: TextStyle(fontWeight: FontWeight.bold)),
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

              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
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
        title: const Text('确认清除'),
        content: Text("确定要清除所有${isPlayback ? '播放' : '订阅'}历史记录吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
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
            child: const Text('确定'),
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
          title: const Text('确认清除'),
          content: const Text('确定要清除所有缓存吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 清除缓存逻辑
                // Navigator.pop(context);
                DefaultCacheManager().emptyCache();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('应用缓存已清除')));
              },
              child: const Text('确定'),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法打开GitHub链接')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开链接失败: $e')));
      }
    }
  }

  String _getThemeModeText() {
    final themeMode = MyApp.themeNotifier.value;
    switch (themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  void _showThemeModeDialog() {
    ThemeMode? currentTheme = MyApp.themeNotifier.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Radio<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: currentTheme,
                    onChanged: (value) {
                      setState(() {
                        currentTheme = value;
                      });
                    },
                  ),
                  title: const Text('跟随系统'),
                  onTap: () {
                    setState(() {
                      currentTheme = ThemeMode.system;
                    });
                  },
                ),
                ListTile(
                  leading: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: currentTheme,
                    onChanged: (value) {
                      setState(() {
                        currentTheme = value;
                      });
                    },
                  ),
                  title: const Text('浅色'),
                  onTap: () {
                    setState(() {
                      currentTheme = ThemeMode.light;
                    });
                  },
                ),
                ListTile(
                  leading: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: currentTheme,
                    onChanged: (value) {
                      setState(() {
                        currentTheme = value;
                      });
                    },
                  ),
                  title: const Text('深色'),
                  onTap: () {
                    setState(() {
                      LocalStore.setString(
                        'theme_mode',
                        currentTheme.toString(),
                      );
                      MyApp.themeNotifier.value = currentTheme!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              MyApp.themeNotifier.value = currentTheme!;
              LocalStore.setString('theme_mode', currentTheme.toString());
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSignoutAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出账号'),
        content: const Text('确定删除当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _email = null;
              });
              LocalStore.removeLocalAccount();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
