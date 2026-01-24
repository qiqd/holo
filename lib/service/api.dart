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

class Api {
  static Bangumi bangumi = Bangumi();
  static Logvar logvar = Logvar();
  static AnimeTrace animeTrace = AnimeTrace();

  static final List<SourceService> _sources = [];
  static void initSources() {
    _sources.clear();
    _sources.addAll([AAfun(), Senfen(), Girugiru(), Mwcy(), Mengdao()]);
    var ruleList = LocalStore.getRules();
    var commonSources = ruleList
        .where((rule) => rule.isEnabled)
        .map((rule) => Common.build(rule))
        .toList();
    _sources.addAll(commonSources);
    delayTest();
  }

  static List<SourceService> getSources() {
    _sources.sort((a, b) => a.delay.compareTo(b.delay));
    return _sources;
  }

  static Future<void> delayTest() async {
    final futures = _sources.map((source) async {
      try {
        final response = await HttpUtil.createDio().getWithTiming(
          source.getBaseUrl().contains('http')
              ? source.getBaseUrl()
              : 'https://${source.getBaseUrl()}',
        );
        final duration = response.extra['request_duration'] as int?;
        source.delay = duration ?? 9999;
      } catch (e) {
        source.delay = 9999;
      }
    }).toList();
    await Future.wait(futures);
  }
}
