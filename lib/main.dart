import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_holo/api/playback_api.dart';
import 'package:mobile_holo/api/subscribe_api.dart';
import 'package:mobile_holo/entity/subject.dart' show Data;
import 'package:mobile_holo/service/api.dart';
import 'package:mobile_holo/service/source_service.dart';
import 'package:mobile_holo/ui/screen/sign.dart';
import 'package:mobile_holo/util/local_store.dart';

import 'package:mobile_holo/ui/screen/calendar.dart';
import 'package:mobile_holo/ui/screen/detail.dart';

import 'package:mobile_holo/ui/screen/home.dart';
import 'package:mobile_holo/ui/screen/player.dart';
import 'package:mobile_holo/ui/screen/search.dart';

import 'package:mobile_holo/ui/screen/setting.dart';
import 'package:mobile_holo/ui/screen/subscribe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  runApp(const MyApp());
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
    ],
  );
  void initSource() async {
    await Api.delayTest();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    MyApp.themeNotifier.value = ThemeMode.values.firstWhere(
      (element) => element.toString() == LocalStore.getString('theme_mode'),
      orElse: () => ThemeMode.system,
    );
    initSource();
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
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          title: 'MikuFans',
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
