import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_holo/main.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mobile_holo/service/util/local_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SetttingScreen extends StatefulWidget {
  const SetttingScreen({super.key});

  @override
  State<SetttingScreen> createState() => _SetttingScreenState();
}

class _SetttingScreenState extends State<SetttingScreen> {
  String _version = '';

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
            subtitle: const Text('删除所有观看记录'),
            onTap: () => _clearHistory(),
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

          // 开源项目特色部分
          _buildSectionHeader('开源项目'),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('源代码'),
            subtitle: const Text('在GitHub上查看源代码'),
            onTap: () => _openGitHub('https://github.com/qiqd/mobile_holo'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('报告问题'),
            subtitle: const Text('提交Bug或功能建议'),
            onTap: () =>
                _openGitHub('https://github.com/qiqd/mobile_holo/issues'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('给项目点赞'),
            subtitle: const Text('在GitHub上为项目点星'),
            onTap: () => _openGitHub('https://github.com/qiqd/mobile_holo'),
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
              const Text('第三方库', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• flutter - BSD License'),
              const Text('• dio - MIT License'),
              const Text('• shared_preferences - BSD License'),
              const Text('• url_launcher - BSD License'),
              const Text('• package_info_plus - BSD License'),
              const Text('• path_provider - BSD License'),
              const SizedBox(height: 8),

              const Text(
                '番剧元信息',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Bangumi 番组计划'),
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

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有观看历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 清除历史逻辑
              Navigator.pop(context);
              LocalStore.clearHistory();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('观看历史已清除')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _clearFavorites() {
    // 类似清除历史的逻辑
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
}
