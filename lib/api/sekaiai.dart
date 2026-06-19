import 'package:holo/entity/daily_mantra.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/logger_util.dart';

class Sekaiai {
  static const String baseUrl = "https://hi.logacg.com";

  ///获取随机句子,出现异常时返回空字符串
  ///a动画,b漫画,c游戏,d文学,e原创,f来自网络,g其他,h影视,i诗词,j网易云,k哲学,l抖机灵
  static Future<DailyMantra?> fetch({String type = "a"}) async {
    try {
      final dio = await HttpUtil.createDioWithUserAgent(
        timeout: const Duration(seconds: 5),
      );
      final response = await dio.get("$baseUrl?c=$type");
      final data = response.data as Map<String, dynamic>;
      return DailyMantra(
        mantra: data["hitokoto"],
        type: type,
        date: DateTime.now(),
        from: data["from"],
        who: data["from_who"],
      );
    } catch (e) {
      LoggerUtil.logger.e("获取随机句子失败:$e");
      return null;
    }
  }
}
