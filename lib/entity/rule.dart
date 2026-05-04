import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rule.g.dart';

const defaultHeaders = {
  "User-Agent":
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0',
};

@HiveType(typeId: 5)
@JsonSerializable(explicitToJson: true)
class Rule {
  @HiveField(0)
  String name;
  @HiveField(1)
  String baseUrl;
  @HiveField(2)
  String logoUrl;
  @HiveField(3)
  bool useWebView;
  @HiveField(4)
  String version;
  @HiveField(5)
  String searchUrl;
  @HiveField(6)
  RequestMethod searchRequestMethod;
  @HiveField(7)
  Map<String, String> searchRequestBody;
  @HiveField(8)
  Map<String, String> searchRequestHeaders;
  @HiveField(9)
  bool fullSearchUrl;
  @HiveField(10)
  int timeout;
  @HiveField(11)
  String searchSelector;
  @HiveField(12)
  String itemImgSelector;
  @HiveField(13)
  bool itemImgFromSrc;
  @HiveField(14)
  String itemTitleSelector;
  @HiveField(15)
  String itemIdSelector;
  @HiveField(16)
  String? itemGenreSelector;
  @HiveField(17)
  String detailUrl;
  @HiveField(18)
  RequestMethod detailRequestMethod;
  @HiveField(19)
  Map<String, String> detailRequestBody;
  @HiveField(20)
  Map<String, String> detailRequestHeaders;
  @HiveField(21)
  bool fullDetailUrl;
  @HiveField(22)
  String lineSelector;
  @HiveField(23)
  String episodeSelector;
  @HiveField(24)
  bool episodeReverse;
  @HiveField(25)
  String playerUrl;
  @HiveField(26)
  RequestMethod playerRequestMethod;
  @HiveField(27)
  Map<String, String> playerRequestBody;
  @HiveField(28)
  Map<String, String> playerRequestHeaders;
  @HiveField(29)
  bool fullPlayerUrl;
  @HiveField(30)
  String playerVideoSelector;
  @HiveField(31)
  String videoElementAttribute;
  @HiveField(32)
  String embedVideoSelector;
  @HiveField(33)
  bool waitForMediaElement;
  @HiveField(34)
  String videoUrlSubsChar;
  @HiveField(35)
  DateTime updateAt;
  @HiveField(36)
  bool isEnabled;
  @HiveField(37)
  bool isLocal;
  @HiveField(38)
  String email;

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
    this.waitForMediaElement = true,
    this.episodeReverse = false,
    this.searchRequestHeaders = defaultHeaders,
    this.detailRequestHeaders = defaultHeaders,
    this.playerRequestHeaders = defaultHeaders,
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
