import 'dart:ui';

import 'package:holo/entity/subject.dart';

String getTitle(Data data) {
  var locale = PlatformDispatcher.instance.locale;
  var title = switch (locale.languageCode) {
    "zh" => data.nameCn ?? '',
    "ja" => data.name ?? '',
    _ => data.name ?? '',
  };
  return title.isNotEmpty ? title : data.name ?? '';
}
