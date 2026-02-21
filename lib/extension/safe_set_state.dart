// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';

/// State 扩展类，添加安全的 setState 方法
extension SafeSetState<T extends StatefulWidget> on State<T> {
  /// 安全的 setState 方法
  /// 只有在 widget 挂载时才执行 setState
  /// [fn]: 要执行的回调函数
  void safeSetState(void Function() fn) {
    if (mounted) {
      setState(fn);
    }
  }
}