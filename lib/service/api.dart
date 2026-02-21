import 'package:holo/service/common.dart';
import 'package:holo/service/impl/animation/aafun.dart';
import 'package:holo/service/impl/animation/girugiru.dart';
import 'package:holo/service/impl/animation/mengdao.dart';
import 'package:holo/service/impl/animation/mwcy.dart';
import 'package:holo/service/impl/animation/senfen.dart';
import 'package:holo/service/impl/meta/anime_trace.dart';
import 'package:holo/service/impl/meta/bangumi.dart';
import 'package:holo/service/impl/meta/logvar.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/dio_timing_extension.dart';
import 'package:holo/util/http_util.dart';
import 'package:holo/util/local_store.dart';

/// API服务管理类
/// 负责管理各种元数据服务和动画源服务
class Api {
  /// Bangumi元数据服务实例
  static Bangumi bangumi = Bangumi();

  /// 弹幕服务实例
  static Logvar logvar = Logvar();

  /// 动漫追踪服务实例
  static AnimeTrace animeTrace = AnimeTrace();

  /// 动画源服务列表
  static final List<SourceService> _sources = [];

  /// 初始化动画源服务
  /// 清空现有源，添加内置源和用户规则源
  static void initSources() {
    // 清空现有源
    _sources.clear();
    // 添加内置动画源
    _sources.addAll([AAfun(), Senfen(), Girugiru(), Mwcy(), Mengdao()]);
    // 获取用户规则
    var ruleList = LocalStore.getRules();
    // 构建启用的规则源
    var commonSources = ruleList
        .where((rule) => rule.isEnabled)
        .map((rule) => Common.build(rule))
        .toList();
    // 添加规则源
    _sources.addAll(commonSources);
  }

  /// 获取动画源服务列表
  /// 按延迟时间排序后返回
  /// 返回排序后的源服务列表
  static List<SourceService> getSources() {
    // 按延迟时间排序
    _sources.sort((a, b) => a.delay.compareTo(b.delay));
    return _sources;
  }

  /// 测试所有动画源的延迟
  /// 并行测试每个源的响应时间，并更新延迟值
  static Future<void> delayTest() async {
    // 并行测试所有源
    final futures = _sources.map((source) async {
      try {
        // 构建完整URL
        final url = source.getBaseUrl().contains('http')
            ? source.getBaseUrl()
            : 'https://${source.getBaseUrl()}';
        // 发起带计时的请求
        final response = await HttpUtil.createDio().getWithTiming(url);
        // 获取请求延迟
        final duration = response.extra['request_duration'] as int?;
        // 更新源的延迟值
        source.delay = duration ?? 9999;
      } catch (e) {
        // 出错时设置为最大延迟
        source.delay = 9999;
      }
    }).toList();
    // 等待所有测试完成
    await Future.wait(futures);
  }
}
