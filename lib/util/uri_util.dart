import 'package:holo/env/env.dart';

String http2Https(String? url) {
  if (url == null) {
    return '';
  }

  final temp =
      (url.startsWith("https://")
              ? url
              : url.replaceFirst("http://", "https://"))
          .replaceFirst("https://lain.bgm.tv", Env.imgServerUrl);

  return temp;
}
