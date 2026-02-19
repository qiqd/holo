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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await LocalStore.init();
  await Bangumi.initDio();
  Api.initSources();
  VideoPlayerMediaKit.ensureInitialized(windows: true, linux: true);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    if (!await FlutterSingleInstance().isFirstInstance()) {
      await FlutterSingleInstance().focus();
      exit(0);
    }
    WindowOptions windowOptions = WindowOptions(
      size: Size(1000, 800),
      minimumSize: Size(800, 600),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('ja', 'JP'),
      ],
      path: 'lib/assets/translations',
      fallbackLocale: Locale('zh', 'CN'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  static final appSettingNotifier = ValueNotifier<AppSetting>(
    LocalStore.getAppSetting(),
  );
  const MyApp({super.key});
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router = GoRouter(
    // observers: [routeObserver],
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscribe',
                builder: (context, state) => SubscribeScreen(),
              ),
            ],
          ),
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
      GoRoute(
        path: '/search',
        builder: (context, state) {
          return SearchScreen();
        },
      ),
      GoRoute(
        path: '/sign',
        builder: (context, state) {
          return AccountScreen();
        },
      ),

      GoRoute(
        path: '/image_search',
        builder: (context, state) {
          return ImageSearchScreen();
        },
      ),
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
      GoRoute(
        path: '/rule_manager',
        builder: (context, state) {
          return RuleManager();
        },
      ),

      GoRoute(
        path: '/rule_repository',
        builder: (context, state) {
          return RuleRepository();
        },
      ),
      GoRoute(
        path: '/rule_test',
        builder: (context, state) {
          return RuleTestScreen(source: state.extra as SourceService);
        },
      ),
      GoRoute(
        path: '/appearence',
        builder: (context, state) {
          return Appearance();
        },
      ),
    ],
  );
  void initSource() async {
    await Api.delayTest();
  }

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
    MyApp.initAppSetting();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemNavigationBarColor(MediaQuery.platformBrightnessOf(context));
    });
    initSource();
  }

  @override
  void didChangePlatformBrightness() {
    _updateSystemNavigationBarColor(MediaQuery.platformBrightnessOf(context));
    super.didChangePlatformBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: MyApp.appSettingNotifier,
      builder: (context, setting, child) {
        return MaterialApp.router(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          themeMode: ThemeMode.values.firstWhere(
            (element) => element.index == setting.themeMode,
            orElse: () => ThemeMode.system,
          ),
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
          theme: ThemeData(
            useSystemColors: setting.useSystemColor,
            brightness: Brightness.light,
            colorSchemeSeed: setting.useSystemColor
                ? null
                : Color(setting.colorSeed),
            useMaterial3: true,
          ),
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

class ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  @override
  Widget build(BuildContext context) {
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
                selectedIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  widget.navigationShell.goBranch(index);
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.primary,
                ),
                unselectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
          showSelectedLabels: false,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) => widget.navigationShell.goBranch(index),
        ),
        body: widget.navigationShell,
      );
    }
  }
}
