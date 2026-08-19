import 'package:flutter/material.dart';
import 'package:holo/util/logger_util.dart';

class ObserverNavigator extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    LoggerUtil.logger.i("didPop: ${route.settings.name}");
    if (route.isCurrent) {
      LoggerUtil.logger.i("isCurrent: ${route.settings.name}");
    }
    if (route.isFirst) {
      LoggerUtil.logger.i("isFirst: ${route.settings.name}");
    }
    final stackLength = navigator?.widget.pages.length ?? 0;
    LoggerUtil.logger.i("当前页面栈长度: $stackLength");
    super.didPop(route, previousRoute);
  }
}
