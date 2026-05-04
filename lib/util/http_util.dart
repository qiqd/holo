import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// HTTP 工具类
/// 用于创建和配置 Dio 实例，模拟浏览器请求
class HttpUtil {
  /// 用户代理列表，用于随机选择模拟不同浏览器
  static final List<String> userAgents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36 Edg/128.0.2792.75",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:129.0) Gecko/20100101 Firefox/129.0",
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Mobile Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.127 Safari/537.36",
  ];

  /// 创建配置好的 Dio 实例，模拟浏览器请求
  static Dio createDio({
    Duration timeout = const Duration(seconds: 20),
    String referer = "",
  }) {
    final dio = Dio();
    // 基础配置
    dio.options
      ..headers = {
        'User-Agent': userAgents[Random().nextInt(userAgents.length)],
        'Accept': '*/*',
      }
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..sendTimeout = timeout;
    if (referer.isNotEmpty) {
      dio.options.headers['Referer'] = referer;
    }

    return dio;
  }

  /// 创建带有自定义 User-Agent 的 Dio 实例
  /// [timeout]: 超时时间，默认为 20 秒
  /// 返回配置好的 Dio 实例
  static Future<Dio> createDioWithUserAgent({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final dio = Dio();
    var packageInfo = await PackageInfo.fromPlatform();
    dio.options
      ..headers = {
        'User-Agent':
            "${packageInfo.appName}/${packageInfo.version} (Android,IOS)(https://github.com/qiqd/holo)",
        'Accept': '*/*',
      }
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..sendTimeout = timeout;
    return dio;
  }

  static Dio createDioWithAuthorization({
    required String serverUrl,
    required String email,
    required String secret,
  }) {
    final dio = createDio();
    dio.options.baseUrl = serverUrl;
    dio.options.contentType = "application/json";
    dio.options.headers["User-Agent"] = "Holo/client";
    dio.options.headers["Authorization"] =
        "Basic ${base64.encode(utf8.encode("$email:$secret"))}";
    return dio;
  }
}
