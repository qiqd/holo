import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import 'package:holo/entity/subject.dart' show Data;
import 'package:holo/service/api.dart';
import 'package:holo/service/impl/meta/bangumi.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/screen/image_search.dart';
import 'package:holo/ui/screen/sign.dart';
import 'package:holo/util/local_store.dart';

import 'package:holo/ui/screen/calendar.dart';
import 'package:holo/ui/screen/detail.dart';

import 'package:holo/ui/screen/home.dart';
import 'package:holo/ui/screen/player.dart';
import 'package:holo/ui/screen/search.dart';

import 'package:holo/ui/screen/setting.dart';
import 'package:holo/ui/screen/subscribe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  await Bangumi.initDio();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('ja', 'JP'),
      ],
      path: 'lib/assert/translations',
      fallbackLocale: Locale('zh', 'CN'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  const MyApp({super.key});

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
          return SignScreen();
        },
      ),

      GoRoute(
        path: '/image_search',
        builder: (context, state) {
          return ImageSearchScreen();
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
    WidgetsBinding.instance.addObserver(this);

    MyApp.themeNotifier.value = ThemeMode.values.firstWhere(
      (element) => element.toString() == LocalStore.getString('theme_mode'),
      orElse: () => ThemeMode.system,
    );
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xffd08b57),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xffd08b57),
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
        );
      },
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // final router = GoRouter.of(context);
    // var currentPath = router.routerDelegate.currentConfiguration.uri.toString();
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_rounded),
            label: 'Subscribe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Setting',
          ),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
      ),
      body: navigationShell,
    );
  }
}
