import 'package:dio/dio.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/util/http_util.dart';
import 'package:logger/web.dart';

/// 规则相关API服务类
/// 提供规则的获取功能
class RuleApi {
  /// 带有拦截器的Dio实例
  static Dio dio = HttpUtil.createDioWithInterceptor();

  /// 日志记录器
  static final Logger _logger = Logger();

  /// 获取规则列表
  /// [onError] 错误回调
  /// 返回规则列表
  static Future<List<Rule>> getRules({Function(String error)? onError}) async {
    try {
      // 发起获取规则的请求
      final response = await dio.get("/rule");
      if (response.statusCode == 200) {
        // 解析响应数据
        final rules = (response.data as List)
            .map((e) => Rule.fromJson(e))
            .toList();

        return rules;
      }
      return [];
    } catch (e) {
      _logger.e("Get rules error: $e");
      onError?.call(e.toString());
      return [];
    }
  }
}
