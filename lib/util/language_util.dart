import 'dart:ui';

import 'package:holo/entity/subject.dart';

/// 根据当前系统语言获取适当的标题
/// [data]: 主题数据对象
/// 返回根据系统语言选择的标题字符串
String getTitle(Data data) {
  var locale = PlatformDispatcher.instance.locale;
  var title = switch (locale.languageCode) {
    "zh" => data.nameCn ?? '',
    "ja" => data.name ?? '',
    _ => data.name ?? '',
  };
  return title.isNotEmpty ? title : data.name ?? '';
}