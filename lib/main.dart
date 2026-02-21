import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/setting_api.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/entity/subject.dart' show Data;
import 'package:holo/service/api.dart';
import 'package:holo/service/impl/meta/bangumi.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/screen/appearance.dart';
import 'package:holo/ui/screen/image_search.dart';
import 'package:holo/ui/screen/player.dart';
import 'package:holo/ui/screen/rule_edit.dart';
import 'package:holo/ui/screen/rule_manager.dart';
import 'package:holo/ui/screen/rule_repository.dart';
import 'package:holo/ui/screen/rule_test.dart';
import 'package:holo/ui/screen/account.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/screen/calendar.dart';
import 'package:holo/ui/screen/detail.dart';
import 'package:holo/ui/screen/home.dart';
import 'package:holo/ui/screen/search.dart';
import 'package:holo/ui/screen/setting.dart';
import 'package:holo/ui/screen/subscribe.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:window_manager/window_manager.dart';

/// 应用程序入口函数
/// 初始化各种服务和配置，然后启动应用
void main() async {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化国际化
  await EasyLocalization.ensureInitialized();
  // 初始化本地存储
  await LocalStore.init();
  // 初始化Bangumi服务的Dio实例
  await Bangumi.initDio();
  // 初始化动画源服务
  Api.initSources();
  // 确保视频播放器已初始化（Windows和Linux平台）
  VideoPlayerMediaKit.ensureInitialized(windows: true, linux: true);
  
  // 桌面平台特殊处理
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 初始化窗口管理器
    await windowManager.ensureInitialized();
    // 检查是否已有实例运行
    if (!await FlutterSingleInstance().isFirstInstance()) {
      // 如果已有实例，聚焦到该实例并退出当前进程
      await FlutterSingleInstance().focus();
      exit(0);
    }
    // 配置窗口选项
    WindowOptions windowOptions = WindowOptions(
      size: Size(1000, 800),
      minimumSize: Size(800, 600),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    // 等待窗口准备就绪后显示并聚焦
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // 运行应用
  runApp(
    EasyLocalization(
      // 支持的语言列表
      supportedLocales: [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('ja', 'JP'),
      ],
      // 翻译文件路径
      path: 'lib/assets/translations',
      //  fallback语言
      fallbackLocale: Locale('zh', 'CN'),
      // 应用主组件
      child: MyApp(),
    ),
  );
}

/// 应用程序主组件
class MyApp extends StatefulWidget {
  /// 应用设置变更通知器
  static final appSettingNotifier = ValueNotifier<AppSetting>(
    LocalStore.getAppSetting(),
  );
  
  /// 构造函数
  const MyApp({super.key});
  
  /// 初始化应用设置
  /// 从服务器获取设置，如果获取失败则使用本地存储的设置
  static Future<void> initAppSetting() async {
    final setting = await SettingApi.fetchSetting((msg) {});
    if (setting != null) {
      LocalStore.saveAppSetting(setting, isSync: false);
    }
    var appSetting = setting ?? LocalStore.getAppSetting();
    MyApp.appSettingNotifier.value = appSetting;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

/// MyApp的状态管理类
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  /// 路由配置
  late final GoRouter _router = GoRouter(
    // 初始路由
    initialLocation: '/home',
    // 路由定义
    routes: [
      // 底部导航栏路由栈
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 首页路由分支
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
            ],
          ),
          // 日历路由分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => CalendarScreen(),
              ),
            ],
          ),
          // 订阅路由分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscribe',
                builder: (context, state) => SubscribeScreen(),
              ),
            ],
          ),
          // 设置路由分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/setting',
                builder: (context, state) => SetttingScreen(),
              ),
            ],
          ),
        ],
      ),
      // 详情页路由
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>;
          return DetailScreen(
            id: map['id'] as int,
            keyword: map['keyword'] as String,
            cover: map['cover'] as String,
            from: map['from'] as String,
            subject: map['subject'] as Data?,
          );
        },
      ),

      // 播放器路由
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>;
          return PlayerScreen(
            mediaId: map['mediaId'] as String,
            subject: map['subject'] as Data,
            source: map['source'] as SourceService,
            nameCn: map['nameCn'] as String,
            isLove: map['isLove'] as bool,
          );
        },
      ),
      // 搜索页路由
      GoRoute(
        path: '/search',
        builder: (context, state) {
          return SearchScreen();
        },
      ),
      // 账户页路由
      GoRoute(
        path: '/sign',
        builder: (context, state) {
          return AccountScreen();
        },
      ),

      // 图片搜索页路由
      GoRoute(
        path: '/image_search',
        builder: (context, state) {
          return ImageSearchScreen();
        },
      ),
      // 规则编辑页路由
      GoRoute(
        path: '/rule_edit',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>?;
          return RuleEditScreen(
            rule: map?['rule'] as Rule?,
            isEditMode: map?['isEditMode'] as bool? ?? false,
          );
        },
      ),
      // 规则管理页路由
      GoRoute(
        path: '/rule_manager',
        builder: (context, state) {
          return RuleManager();
        },
      ),

      // 规则仓库页路由
      GoRoute(
        path: '/rule_repository',
        builder: (context, state) {
          return RuleRepository();
        },
      ),
      // 规则测试页路由
      GoRoute(
        path: '/rule_test',
        builder: (context, state) {
          return RuleTestScreen(source: state.extra as SourceService);
        },
      ),
      // 外观设置页路由
      GoRoute(
        path: '/appearence',
        builder: (context, state) {
          return Appearance();
        },
      ),
    ],
  );
  
  /// 初始化动画源服务并测试延迟
  void initSource() async {
    await Api.delayTest();
  }

  /// 更新系统导航栏颜色
  /// [b] 亮度模式
  void _updateSystemNavigationBarColor(Brightness b) {
    Color navigationBarColor;
    Brightness iconBrightness;

    if (b == Brightness.dark) {
      navigationBarColor = const Color(0xff141400);
      iconBrightness = Brightness.light;
    } else {
      navigationBarColor = const Color(0xfffff8f5);
      iconBrightness = Brightness.dark;
    }
    // 设置系统UI覆盖样式
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 初始化应用设置
    MyApp.initAppSetting();
    // 添加Widget绑定观察者
    WidgetsBinding.instance.addObserver(this);
    // 首次构建后更新导航栏颜色
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemNavigationBarColor(MediaQuery.platformBrightnessOf(context));
    });
    // 初始化动画源
    initSource();
  }

  @override
  void didChangePlatformBrightness() {
    // 平台亮度变化时更新导航栏颜色
    _updateSystemNavigationBarColor(MediaQuery.platformBrightnessOf(context));
    super.didChangePlatformBrightness();
  }

  @override
  void dispose() {
    // 移除Widget绑定观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      // 监听应用设置变化
      valueListenable: MyApp.appSettingNotifier,
      builder: (context, setting, child) {
        return MaterialApp.router(
          // 本地化代理
          localizationsDelegates: context.localizationDelegates,
          // 支持的语言
          supportedLocales: context.supportedLocales,
          // 当前语言
          locale: context.locale,
          // 隐藏调试横幅
          debugShowCheckedModeBanner: false,
          // 路由配置
          routerConfig: _router,
          // 主题模式
          themeMode: ThemeMode.values.firstWhere(
            (element) => element.index == setting.themeMode,
            orElse: () => ThemeMode.system,
          ),
          // 背景图片构建器
          builder: LocalStore.getBackgroundImagePath().isEmpty
              ? null
              : (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(
                          File(LocalStore.getBackgroundImagePath()),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: child,
                  );
                },
          // 浅色主题
          theme: ThemeData(
            useSystemColors: setting.useSystemColor,
            brightness: Brightness.light,
            colorSchemeSeed: setting.useSystemColor
                ? null
                : Color(setting.colorSeed),
            useMaterial3: true,
          ),
          // 深色主题
          darkTheme: ThemeData(
            useSystemColors: setting.useSystemColor,
            colorSchemeSeed: setting.useSystemColor
                ? null
                : Color(setting.colorSeed),
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
        );
      },
    );
  }
}

/// 带导航栏的脚手架组件
class ScaffoldWithNavBar extends StatefulWidget {
  /// 导航外壳，用于管理导航状态
  final StatefulNavigationShell navigationShell;
  
  /// 构造函数
  /// [navigationShell] 导航外壳实例
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

/// ScaffoldWithNavBar的状态管理类
class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  @override
  Widget build(BuildContext context) {
    // 获取当前设备方向
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      // 横屏布局 - 使用侧边导航栏
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(
            vertical: Platform.isLinux || Platform.isWindows || Platform.isMacOS
                ? 12
                : 0,
          ),
          child: Row(
            children: [
              // 侧边导航栏
              NavigationRail(
                leading: Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search_rounded),
                      onPressed: () {
                        context.push('/search');
                      },
                    ),
                  ],
                ),
                // 当前选中索引
                selectedIndex: widget.navigationShell.currentIndex,
                // 选择目标回调
                onDestinationSelected: (index) {
                  widget.navigationShell.goBranch(index);
                },
                // 背景颜色
                backgroundColor: Theme.of(context).colorScheme.surface,
                // 选中图标主题
                selectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.primary,
                ),
                // 未选中图标主题
                unselectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                // 导航目标
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_rounded),
                    label: Text('home.title'.tr()),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_rounded),
                    label: Text('calendar.title'.tr()),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.subscriptions_rounded),
                    label: Text('subscribe.title'.tr()),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_rounded),
                    label: Text('setting.title'.tr()),
                  ),
                ],
                // 标签类型
                labelType: NavigationRailLabelType.none,
              ),
              VerticalDivider(width: 1),
              // 主内容区域
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
      );
    } else {
      // 竖屏布局 - 使用底部导航栏
      return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          // 是否显示选中标签
          showSelectedLabels: false,
          // 选中项颜色
          selectedItemColor: Theme.of(context).colorScheme.primary,
          // 未选中项颜色
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          // 导航项
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'home.title'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'calendar.title'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions_rounded),
              label: 'subscribe.title'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'setting.title'.tr(),
            ),
          ],
          // 当前选中索引
          currentIndex: widget.navigationShell.currentIndex,
          // 点击回调
          onTap: (index) => widget.navigationShell.goBranch(index),
        ),
        // 主内容区域
        body: widget.navigationShell,
      );
    }
  }
}
