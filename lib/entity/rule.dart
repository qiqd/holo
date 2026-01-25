import 'package:json_annotation/json_annotation.dart';

part 'rule.g.dart';

@JsonSerializable(explicitToJson: true)
class Rule {
  /// 规则名称(通常为网站名称)
  String name;

  /// 规则baseUrl(通常是网站的域名)
  String baseUrl;

  /// 规则logoUrl(通常是网站的logo)
  String logoUrl;

  ///规则版本号
  String version;

  /// 搜索Url(通常是网站的搜索页面)
  String searchUrl;

  /// 搜索请求方法(默认get)
  RequestMethod searchRequestMethod;

  /// 搜索请求体(通常是网站的搜索页面的请求体)
  Map<String, String> searchRequestBody;

  ///搜索请求头部(通常是网站的搜索页面的请求头部)
  Map<String, String> searchRequestHeaders;

  /// 是否是完整的搜索Url(如果是,则不与 baseUrl 拼接,否则拼接)
  bool fullSearchUrl;

  /// 超时时间(默认5秒)
  int timeout;

  /// 搜索选择器(通常是搜索结果的列表)
  String searchSelector;

  /// 搜索图片选择器(通常是搜索结果的列表中的每一项的图片,一般是一个img标签)
  String itemImgSelector;

  /// 是否是图片选择器中的src属性(如果是,则图片选择器中的src属性是图片的url,否则是data-original属性)
  bool itemImgFromSrc;

  /// 搜索标题选择器(通常是搜索结果的列表中的每一项的标题,一般是一个a标签)
  String itemTitleSelector;

  /// MediaId选择器(通常是搜索结果的列表中的每一项的Id,一般是一个a标签)
  String itemIdSelector;

  /// 搜索类型选择器(通常是搜索结果的列表中的每一项的内容的类型)
  String? itemGenreSelector;

  /// 详情Url(通常是网站的详情页面)
  String detailUrl;

  /// 详情请求方法(默认get)
  RequestMethod detailRequestMethod;

  /// 详情请求体(通常是网站的详情页面的请求体)
  Map<String, String> detailRequestBody;

  /// 详情请求头部(通常是网站的详情页面的请求头部)
  Map<String, String> detailRequestHeaders;

  /// 是否是完整的详情Url(如果是,则不与 baseUrl 拼接,否则拼接)
  bool fullDetailUrl;

  /// 路线选择器(该视频的播放路线)
  String lineSelector;

  /// 剧集选择器(每一条线路下对应的剧集,一般是一个a标签)
  String episodeSelector;

  /// 播放页面Url(通常是网站的播放页面的视频播放地址)
  String playerUrl;

  /// 播放页面请求方法(默认get)
  RequestMethod playerRequestMethod;

  /// 播放页面请求体(通常是网站的播放页面的请求体)
  Map<String, String> playerRequestBody;

  /// 播放页面请求头部(通常是网站的播放页面的请求头部)
  Map<String, String> playerRequestHeaders;

  /// 是否是完整的播放Url(如果是 ,则不与 baseUrl 拼接,否则拼接)
  bool fullPlayerUrl;

  /// 播放视频选择器(通常是播放页面的视频标签,比如video,iframe等)
  String playerVideoSelector;

  /// 视频元素属性(通常是视频标签的src属性,比如video标签的src属性)
  String? videoElementAttribute;

  /// 嵌入视频选择器,英文逗号分隔(通常是播放页面的嵌入视频标签,比如iframe等)
  String? embedVideoSelector;

  /// 是否等待视频元素加载完成(如果是,则等待视频元素加载完成,否则立即返回)
  bool waitForMediaElement;

  ///视频url截取,通常是从params参数中截取视频url,比如params=videoUrl=xxxx,则截取xxxx,如果是null,则直接返回匹配的url
  String? videoUrlSubsChar;

  /// 规则更新时间
  DateTime updateAt;

  //规则是否启用
  bool isEnabled;

  //是否是本地规则
  bool isLocal;

  Rule({
    this.name = '',
    this.logoUrl = '',
    this.searchUrl = '',
    this.detailUrl = '',
    this.playerUrl = '',
    this.searchSelector = '',
    this.lineSelector = '',
    this.episodeSelector = '',
    this.playerVideoSelector = '',
    this.itemImgSelector = '',
    this.itemTitleSelector = '',
    this.itemIdSelector = '',
    this.baseUrl = '',
    this.fullSearchUrl = false,
    this.fullPlayerUrl = false,
    this.fullDetailUrl = false,
    this.itemImgFromSrc = true,
    this.waitForMediaElement = true,
    this.searchRequestHeaders = const {},
    this.detailRequestHeaders = const {},
    this.playerRequestHeaders = const {},
    this.searchRequestBody = const {},
    this.detailRequestBody = const {},
    this.playerRequestBody = const {},
    this.videoElementAttribute,
    this.version = '1.0',
    this.isEnabled = true,
    this.timeout = 5,
    this.isLocal = true,
    this.searchRequestMethod = RequestMethod.get,
    this.detailRequestMethod = RequestMethod.get,
    this.playerRequestMethod = RequestMethod.get,
    this.embedVideoSelector,
    this.itemGenreSelector,
    this.videoUrlSubsChar,
  }) : updateAt = DateTime.now();

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

  Map<String, dynamic> toJson() => _$RuleToJson(this);
}

enum RequestMethod {
  @JsonValue('get')
  get,
  @JsonValue('post')
  post,
  @JsonValue('put')
  put,
  @JsonValue('delete')
  delete,
  @JsonValue('head')
  head,
  @JsonValue('options')
  options,
}
