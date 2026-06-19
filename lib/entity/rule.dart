import 'package:hive_ce/hive.dart';
import 'package:holo/util/http_option_util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rule.g.dart';

@HiveType(typeId: 5)
@JsonSerializable(explicitToJson: true)
class Rule {
  /// 规则名称
  @HiveField(0)
  String name;

  /// 基础URL
  @HiveField(1)
  String baseUrl;

  /// 图标URL
  @HiveField(2)
  String logoUrl;

  /// 是否使用WebView，如果为true，需要在WebView中加载页面， 默认值为false
  @HiveField(3)
  bool useWebView;

  /// 版本号,浮点数,默认值为1.0
  @HiveField(4)
  String version;

  /// 搜索URL
  @HiveField(5)
  String searchUrl;

  /// 搜索请求方法
  @HiveField(6)
  RequestMethod searchRequestMethod;

  /// 搜索请求体
  @HiveField(7)
  Map<String, String> searchRequestBody;

  /// 搜索请求头
  @HiveField(8)
  Map<String, String> searchRequestHeaders;

  /// 是否完整搜索URL，如果为true，在发送请求前会自动添加基础URL， 默认值为false
  @HiveField(9)
  bool fullSearchUrl;

  /// 请求超时时间，单位秒，默认值为10
  @HiveField(10)
  int timeout;

  /// 搜索结果选择器
  @HiveField(11)
  String searchSelector;

  /// 搜索结果中每一项的图片选择器
  @HiveField(12)
  String itemImgSelector;

  /// 是否从图片src属性中获取URL， 默认值为true
  @HiveField(13)
  bool itemImgFromSrc;

  /// 项目标题选择器
  @HiveField(14)
  String itemTitleSelector;

  /// 项目ID选择器
  @HiveField(15)
  String itemIdSelector;

  /// 项目类型选择器
  @HiveField(16)
  String? itemGenreSelector;

  /// 项目详情URL
  @HiveField(17)
  String detailUrl;

  /// 项目详情请求方法
  @HiveField(18)
  RequestMethod detailRequestMethod;

  /// 项目详情请求体
  @HiveField(19)
  Map<String, String> detailRequestBody;

  /// 项目详情请求头
  @HiveField(20)
  Map<String, String> detailRequestHeaders;

  /// 是否完整项目详情URL，如果为true，在发送请求前会自动添加基础URL， 默认值为false
  @HiveField(21)
  bool fullDetailUrl;

  /// 项目详情中播放路线选择器
  @HiveField(22)
  String lineSelector;

  /// 项目详情中分集选择器
  @HiveField(23)
  String episodeSelector;

  /// 是否反转分集选择器， 默认值为false
  @HiveField(24)
  bool episodeReverse;

  /// 播放页URL
  @HiveField(25)
  String playerUrl;

  /// 播放页请求方法
  @HiveField(26)
  RequestMethod playerRequestMethod;

  /// 播放页请求体
  @HiveField(27)
  Map<String, String> playerRequestBody;

  /// 播放页请求头
  @HiveField(28)
  Map<String, String> playerRequestHeaders;

  /// 是否完整播放页URL，如果为true，在发送请求前会自动添加基础URL， 默认值为false
  @HiveField(29)
  bool fullPlayerUrl;

  /// 播放页中视频元素选择器
  @HiveField(30)
  String playerVideoSelector;

  /// 播放页中视频元素属性选择器
  @HiveField(31)
  String videoElementAttribute;

  /// 播放页中嵌入式视频选择器
  @HiveField(32)
  String embedVideoSelector;

  /// 是否等待目标元素出现， 默认值为true
  @HiveField(33)
  bool waitForTargetElement;

  /// 视频URL中替换的字符
  @HiveField(34)
  String videoUrlSubsChar;

  /// 规则更新时间
  @HiveField(35)
  DateTime updateAt;

  /// 是否启用， 默认值为true
  @HiveField(36)
  bool isEnabled;

  /// 是否本地规则， 默认值为true
  @HiveField(37)
  bool isLocal;

  /// 邮箱， 默认值为空字符串
  @HiveField(38)
  String email;

  /// 规则是否可用, 默认值为true
  @HiveField(39)
  bool isValid;

  Rule({
    this.name = '',
    this.logoUrl = '',
    this.useWebView = false,
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
    this.waitForTargetElement = true,
    this.episodeReverse = false,
    this.searchRequestHeaders = defaultUserAgent,
    this.detailRequestHeaders = defaultUserAgent,
    this.playerRequestHeaders = defaultUserAgent,
    this.searchRequestBody = const {},
    this.detailRequestBody = const {},
    this.playerRequestBody = const {},
    this.videoElementAttribute = '',
    this.version = '1.0',
    this.isEnabled = true,
    this.timeout = 5,
    this.isLocal = true,
    this.searchRequestMethod = RequestMethod.get,
    this.detailRequestMethod = RequestMethod.get,
    this.playerRequestMethod = RequestMethod.get,
    this.embedVideoSelector = '',
    this.itemGenreSelector = '',
    this.videoUrlSubsChar = '',
    this.email = '',
    this.isValid = true,
  }) : updateAt = DateTime.now();

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
  Map<String, dynamic> toJson() => _$RuleToJson(this);
}

@HiveType(typeId: 6)
enum RequestMethod {
  @HiveField(0)
  @JsonValue('get')
  get,
  @HiveField(1)
  @JsonValue('post')
  post,
}
