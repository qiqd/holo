// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';

extension SafeSetState<T extends StatefulWidget> on State<T> {
  void safeSetState(void Function() fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
