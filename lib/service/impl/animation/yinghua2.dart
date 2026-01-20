import 'package:holo/entity/rule.dart';
import 'package:holo/service/common.dart';
import 'package:holo/util/webview_util.dart';
import 'package:html/parser.dart';

class Yinghua2 extends Common {
  Yinghua2({
    super.rule = const Rule(
      name: "樱花动漫2",
      baseUrl: 'https://www.czzymovie.com',
      logoUrl:
          'https://tv.yinghuadongman.info/upload/mxprocms/20260114-1/f765273ee1a2bd224227ca581fdf22f8.jpg',
      searchUrl:
          'https://tv.yinghuadongman.info/search_-------------.html?wd={keyword}',
      fullSearchUrl: false,
      searchSelector: 'div.module-card-item.module-item',
      itemImgSelector: 'div.module-item-pic img',
      itemImgFromSrc: false,
      itemTitleSelector: 'div.module-card-item-title a',
      itemIdSelector: 'div.module-card-item-title a',
      detailUrl: 'https://tv.yinghuadongman.info{mediaId}',
      fullDetailUrl: false,
      lineSelector: 'div#panel1',
      episodeSelector: 'a',
      playerUrl: 'https://tv.yinghuadongman.info{episodeId}',
      fullPlayerUrl: false,
      playerVideoSelector: 'td#playleft>iframe',
    ),
  });
  @override
  Future<String?> fetchView(
    String episodeId,
    Function(String) exceptionHandler,
  ) async {
    var fadeUrl = await super.fetchView(episodeId, exceptionHandler) ?? '';
    var html = await WebviewUtil.fetchHtml(fadeUrl);
    var doc = parse(html);
    return doc
        .querySelector(
          "div.leleplayer-info-panel-item-url span.leleplayer-info-panel-item-data",
        )
        ?.text;
  }
}
