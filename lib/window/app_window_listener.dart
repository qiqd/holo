import 'dart:developer';

import 'package:window_manager/window_manager.dart';

class AppWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    windowManager.hide();
    log('onWindowClose');
    super.onWindowClose();
  }
}
