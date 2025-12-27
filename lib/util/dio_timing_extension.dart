import 'dart:developer';

import 'package:dio/dio.dart';

extension DioTimingExtension on Dio {
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
