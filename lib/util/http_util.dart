import 'dart:math';
import 'package:dio/dio.dart';

class HttpUtil {
  static final List<String> userAgents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36 Edg/128.0.2792.75",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:129.0) Gecko/20100101 Firefox/129.0",
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.127 Safari/537.36",
  ];

  /// 创建配置好的Dio实例，模拟浏览器请求
  ///
  /// @param url 请求URL
  /// @return 配置好的Dio实例
  static Dio createDio() {
    final dio = Dio();
    // 基础配置
    dio.options
      ..headers = {
        'User-Agent': userAgents[Random().nextInt(userAgents.length)],
        'Accept': '*/*',
      }
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 20);

    return dio;
  }

  static Dio createDioWithUserAgent() {
    final dio = Dio();
    // 基础配置
    dio.options
      ..headers = {
        'User-Agent':
            "mobile_holo/v1.0.0 (Android,IOS)(https://github.com/qiqd/mobile_holo)",
        'Accept': '*/*',
      }
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 20);

    return dio;
  }

  /// 创建带Referer的配置好的Dio实例
  ///
  /// @param url 请求URL
  /// @param referer Referer头
  /// @return 配置好的Dio实例
  static Dio createDioWithReferer(String referer) {
    final dio = createDio();
    dio.options.headers['Referer'] = referer;
    return dio;
  }

  /// 测试多个源的延迟并排序
  ///
  /// @param delays 延迟列表（会清空并重新填充）
  /// @param sources 源映射
  // static Future<void> delayTestSync(
  //   List<SourceDelay> delays,
  //   Map<String, Parser> sources,
  // ) async {
  //   delays.clear();
  //
  //   for (final entry in sources.entries) {
  //     // final name = entry.key;
  //     final parser = entry.value;
  //
  //     try {
  //       final startTime = DateTime.now().millisecondsSinceEpoch;
  //
  //       final dio = Dio();
  //       dio.options
  //         ..baseUrl = parser.baseUrl
  //         ..connectTimeout = const Duration(seconds: 5)
  //         ..receiveTimeout = const Duration(seconds: 5)
  //         ..sendTimeout = const Duration(seconds: 5)
  //         ..followRedirects = true;
  //
  //       final response = await dio.get('');
  //       final endTime = DateTime.now().millisecondsSinceEpoch;
  //
  //       int delay = -1;
  //       if (response.statusCode == 200) {
  //         delay = endTime - startTime;
  //       }
  //
  //       delays.add(SourceDelay(delay, parser));
  //     } catch (e) {
  //       // 日志部分不重构，保持空实现
  //       delays.add(SourceDelay(999999, parser));
  //     }
  //   }
  //
  //   // 按延迟排序
  //   delays.sort((a, b) => (a.delay).compareTo(b.delay));
  // }
}
