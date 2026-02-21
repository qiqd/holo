import 'dart:developer';

import 'package:dio/dio.dart';

/// Dio 扩展类，添加带计时功能的 GET 请求方法
extension DioTimingExtension on Dio {
  /// 发送 GET 请求并记录耗时
  /// [path]: 请求路径
  /// [queryParameters]: 查询参数
  /// [options]: 请求选项
  /// [cancelToken]: 取消令牌
  /// [onReceiveProgress]: 接收进度回调
  /// 返回响应对象，同时在 extra 中添加 request_duration 字段记录耗时
  Future<Response<T>> getWithTiming<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      response.extra['request_duration'] = duration;
      log('GET $path 耗时: ${duration}ms');

      return response;
    } catch (e) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      log('GET $path 失败，耗时: ${duration}ms');
      rethrow;
    }
  }
}