import 'package:json_annotation/json_annotation.dart';

part 'rule.g.dart';

@JsonSerializable()
class Rule {
  /// 规则名称(通常为网站名称)
  final String name;

  /// 规则baseUrl(通常是网站的域名)
  final String baseUrl;

  /// 规则logoUrl(通常是网站的logo)
  final String logoUrl;

  ///规则版本号
  final String version;

  /// 搜索Url(通常是网站的搜索页面)
  final String searchUrl;

  /// 是否是完整的搜索Url(如果是,则不与 baseUrl 拼接,否则拼接)
  final bool fullSearchUrl;

  /// 超时时间(默认5秒)
  final int timeout;

  /// 搜索选择器(通常是搜索结果的列表)
  final String searchSelector;

  /// 搜索图片选择器(通常是搜索结果的列表中的每一项的图片,一般是一个img标签)
  final String itemImgSelector;

  /// 是否是图片选择器中的src属性(如果是,则图片选择器中的src属性是图片的url,否则是data-original属性)
  final bool itemImgFromSrc;

  /// 搜索标题选择器(通常是搜索结果的列表中的每一项的标题,一般是一个a标签)
  final String itemTitleSelector;

  /// MediaId选择器(通常是搜索结果的列表中的每一项的Id,一般是一个a标签)
  final String itemIdSelector;

  /// 搜索类型选择器(通常是搜索结果的列表中的每一项的内容的类型)
  final String? itemGenreSelector;

  /// 详情Url(通常是网站的详情页面)
  final String detailUrl;

  /// 是否是完整的详情Url(如果是,则不与 baseUrl 拼接,否则拼接)
  final bool fullDetailUrl;

  /// 路线选择器(该视频的播放路线)
  final String lineSelector;

  /// 剧集选择器(每一条线路下对应的剧集,一般是一个a标签)
  final String episodeSelector;

  /// 播放页面Url(通常是网站的播放页面的视频播放地址)
  final String playerUrl;

  /// 是否是完整的播放Url(如果是 ,则不与 baseUrl 拼接,否则拼接)
  final bool fullPlayerUrl;

  /// 播放视频选择器(通常是播放页面的视频标签,比如video,iframe等)
  final String playerVideoSelector;

  /// 视频元素属性(通常是视频标签的src属性,比如video标签的src属性)
  final String? videoElementAttribute;

  /// 嵌入视频选择器,英文逗号分隔(通常是播放页面的嵌入视频标签,比如iframe等)
  final String? embedVideoSelector;

  /// 是否等待视频元素加载完成(如果是,则等待视频元素加载完成,否则立即返回)
  final bool waitForMediaElement;

  ///视频url截取,通常是从params参数中截取视频url,比如params=videoUrl=xxxx,则截取xxxx,如果是null,则直接返回匹配的url
  final String? videoUrlSubsChar;

  /// 规则更新时间
  DateTime updateAt;
  //规则是否启用
  bool isEnabled;

  Rule({
    required this.name,
    required this.logoUrl,
    required this.searchUrl,

    required this.fullSearchUrl,
    required this.detailUrl,
    required this.playerUrl,
    required this.fullPlayerUrl,
    required this.searchSelector,
    required this.fullDetailUrl,
    required this.lineSelector,
    required this.episodeSelector,
    required this.playerVideoSelector,
    required this.itemImgSelector,
    required this.itemTitleSelector,
    required this.itemIdSelector,
    required this.baseUrl,
    required this.itemImgFromSrc,
    required this.updateAt,
    required this.waitForMediaElement,
    this.videoElementAttribute,
    this.version = '1.0',
    this.isEnabled = true,
    this.timeout = 5,
    this.embedVideoSelector,
    this.itemGenreSelector,
    this.videoUrlSubsChar,
  });
  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

  Map<String, dynamic> toJson() => _$RuleToJson(this);
}
