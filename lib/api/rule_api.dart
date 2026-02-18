import 'package:dio/dio.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/util/http_util.dart';
import 'package:logger/web.dart';

class RuleApi {
  static Dio dio = HttpUtil.createDioWithInterceptor();
  static final Logger _logger = Logger();
  static Future<List<Rule>> getRules({Function(String error)? onError}) async {
    try {
      final response = await dio.get("/rule");
      if (response.statusCode == 200) {
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
