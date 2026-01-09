import 'dart:math';
import 'package:dio/dio.dart';
import 'package:holo/util/local_store.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    var packageInfo = '1.0.0';
    PackageInfo.fromPlatform().then((value) {
      packageInfo = value.version;
    });
    // 基础配置
    dio.options
      ..headers = {
        'User-Agent':
            "holo/$packageInfo (Android,IOS)(https://github.com/qiqd/holo)",
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

  static Dio createDioWithInterceptor() {
    final dio = createDio();
    dio.options.contentType = "application/json";
    dio.interceptors.add(RequestInterceptor());
    return dio;
  }
}

class RequestInterceptor extends Interceptor {
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
