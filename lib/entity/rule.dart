class Rule {
  /// 规则名称(通常为网站名称)
  final String name;

  /// 规则baseUrl(通常是网站的域名)
  final String baseUrl;

  /// 规则logoUrl(通常是网站的logo)
  final String logoUrl;

  /// 搜索Url(通常是网站的搜索页面)
  final String searchUrl;

  /// 搜索选择器(通常是搜索结果的列表)
  final String searchSelector;

  /// 搜索图片选择器(通常是搜索结果的列表中的每一项的图片,一般是一个img标签)
  final String itemImgSelector;
  final bool itemImgFromSrc;

  /// 搜索标题选择器(通常是搜索结果的列表中的每一项的标题,一般是一个a标签)
  final String itemTitleSelector;

  /// 搜索Id选择器(通常是搜索结果的列表中的每一项的Id,一般是一个a标签)
  final String itemIdSelector;

  /// 搜索类型选择器(通常是搜索结果的列表中的每一项的内容的类型)
  final String? itemGenreSelector;

  /// 详情Url(通常是网站的详情页面)
  final String detailUrl;

  /// 路线选择器(该视频的播放路线)
  final String lineSelector;

  /// 剧集选择器(每一条线路下对应的剧集,一般是一个a标签)
  final String episodeSelector;

  /// 播放Url(通常是网站的播放页面的视频播放地址)
  final String playerUrl;

  /// 播放视频选择器(通常是播放页面的视频标签,比如video,iframe等)
  final String playerVideoSelector;

  final String? videoUrlSubsChar;
  const Rule({
    required this.name,
    required this.logoUrl,
    required this.searchUrl,
    required this.detailUrl,
    required this.playerUrl,
    required this.searchSelector,
    required this.lineSelector,
    required this.episodeSelector,
    required this.playerVideoSelector,
    required this.itemImgSelector,
    required this.itemTitleSelector,
    required this.itemIdSelector,
    required this.baseUrl,
    required this.itemImgFromSrc,
    this.itemGenreSelector,
    this.videoUrlSubsChar,
  });
}
