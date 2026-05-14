// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';

/// State 扩展类，添加安全的 setState 方法
extension SafeSetStateExtension<T extends StatefulWidget> on State<T> {
  /// 安全的 setState 方法
  /// 只有在 widget 挂载时才执行 setState
  /// [callback]: 要执行的回调函数
  void safeSetState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }
}
