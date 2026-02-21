import 'dart:math';
import 'package:dio/dio.dart';
import 'package:holo/util/local_store.dart';
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
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.138 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.127 Safari/537.36",
  ];

  /// 创建配置好的 Dio 实例，模拟浏览器请求
  /// 返回配置好的 Dio 实例
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
            "holo/$packageInfo (Android,IOS)(https://github.com/qiqd/holo)",
        'Accept': '*/*',
      }
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..sendTimeout = timeout;
    return dio;
  }

  /// 创建带 Referer 的配置好的 Dio 实例
  /// [referer]: Referer 头
  /// 返回配置好的 Dio 实例
  static Dio createDioWithReferer(String referer) {
    final dio = createDio();
    dio.options.headers['Referer'] = referer;
    return dio;
  }

  /// 创建带拦截器的配置好的 Dio 实例
  /// 并在请求头中添加 User-Agent, Authorization, Content-Type 请求头
  /// 返回配置好的 Dio 实例
  static Dio createDioWithInterceptor() {
    final dio = createDio();
    dio.options.contentType = "application/json";
    dio.interceptors.add(RequestInterceptor());
    return dio;
  }
}

/// 请求拦截器类
/// 用于在请求头中添加服务器 URL 和认证令牌
class RequestInterceptor extends Interceptor {
  /// 拦截请求并添加必要的头信息
  /// [options]: 请求选项
  /// [handler]: 拦截器处理器
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    var serverUrl = LocalStore.getServerUrl();
    var token = LocalStore.getToken();
    if (serverUrl == null) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: null,
          message: "ServerUrl is null",
        ),
      );
      return;
    }
    options.baseUrl = serverUrl;
    options.contentType = "application/json";
    options.headers["User-Agent"] = "Holo/client";
    if (token != null) {
      options.headers["Authorization"] = token;
    }
    handler.next(options);
  }
}