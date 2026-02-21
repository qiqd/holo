import 'dart:convert';
import 'dart:developer';
import 'package:holo/api/setting_api.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/entity/calendar.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储管理类，使用 SharedPreferences 进行数据持久化
class LocalStore {
  /// 存储键前缀
  static const String _key = "holo_local_store";
  /// SharedPreferences 实例
  static SharedPreferences? _prefs;

  /// 初始化本地存储
  /// 异步获取 SharedPreferences 实例
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取服务器 URL
  /// 返回存储的服务器 URL，若不存在则返回 null
  static String? getServerUrl() {
    return _prefs!.getString("${_key}_server_url");
  }

  /// 设置服务器 URL
  /// [serverUrl]: 服务器 URL 字符串
  static void setServerUrl(String serverUrl) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_server_url", serverUrl);
  }

  /// 获取认证令牌
  /// 返回存储的令牌，若不存在则返回 null
  static String? getToken() {
    return _prefs!.getString("${_key}_token");
  }

  /// 设置认证令牌
  /// [token]: 认证令牌字符串
  static void setToken(String token) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_token", token);
  }

  /// 获取用户邮箱
  /// 返回存储的邮箱，若不存在则返回 null
  static String? getEmail() {
    if (_prefs == null) return null;
    return _prefs!.getString("${_key}_email");
  }

  /// 设置用户邮箱
  /// [email]: 用户邮箱字符串
  static void setEmail(String email) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_email", email);
  }

  /// 移除本地账户信息
  /// 清除存储的令牌、邮箱和服务器 URL
  static void removeLocalAccount() {
    if (_prefs == null) return;
    _prefs!.remove("${_key}_token");
    _prefs!.remove("${_key}_email");
    _prefs!.remove("${_key}_server_url");
  }

  /// 根据订阅 ID 移除订阅历史
  /// [subId]: 订阅 ID
  static void removeSubscribeHistoryBySubId(int subId) {
    if (_prefs == null) return;
    var subsStr = _prefs!.getStringList("${_key}_subscribe") ?? [];
    var subs = subsStr
        .map((jsonStr) => SubscribeHistory.fromJson(json.decode(jsonStr)))
        .toList();
    subs.removeWhere((item) => item.subId == subId);
    subsStr = subs.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_subscribe", subsStr);
  }

  /// 根据订阅 ID 移除播放历史
  /// [subId]: 订阅 ID
  static void removePlaybackHistoryBySubId(int subId) {
    if (_prefs == null) return;
    var playStr = _prefs!.getStringList("${_key}_playback") ?? [];
    var subs = playStr
        .map((jsonStr) => PlaybackHistory.fromJson(json.decode(jsonStr)))
        .toList();
    subs.removeWhere((item) => item.subId == subId);
    playStr = subs.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_playback", playStr);
  }

  /// 添加订阅历史
  /// [history]: 订阅历史对象
  static void addSubscribeHistory(SubscribeHistory history) {
    if (_prefs == null) return;
    var subsStr = _prefs!.getStringList("${_key}_subscribe") ?? [];
    var subs = subsStr
        .map((jsonStr) => SubscribeHistory.fromJson(json.decode(jsonStr)))
        .toList();
    subs.removeWhere((item) => item.subId == history.subId);
    subs.add(history);
    subsStr = subs.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_subscribe", subsStr);
  }

  /// 获取所有订阅历史
  /// 返回订阅历史列表
  static List<SubscribeHistory> getSubscribeHistory() {
    if (_prefs == null) return [];
    var subsStr = _prefs!.getStringList("${_key}_subscribe") ?? [];
    return subsStr
        .map((jsonStr) => SubscribeHistory.fromJson(json.decode(jsonStr)))
        .toList();
  }

  /// 添加播放历史
  /// [history]: 播放历史对象
  /// 返回操作是否成功
  static bool addPlaybackHistory(PlaybackHistory history) {
    if (_prefs == null) return false;
    var playbackStr = _prefs!.getStringList("${_key}_playback") ?? [];
    var playback = playbackStr
        .map((jsonStr) => PlaybackHistory.fromJson(json.decode(jsonStr)))
        .toList();
    var firstWhere = playback.firstWhere(
      (item) => item.subId == history.subId,
      orElse: () => PlaybackHistory(
        id: history.id,
        subId: history.subId,
        position: history.position,
        title: history.title,
        imgUrl: history.imgUrl,
        airDate: history.airDate,
        createdAt: history.createdAt,
        lastPlaybackAt: history.lastPlaybackAt,
        isSync: history.isSync,
        episodeIndex: history.episodeIndex,
        lineIndex: history.lineIndex,
      ),
    );
    playback.removeWhere((item) => item.subId == history.subId);
    firstWhere.position = history.position;
    firstWhere.episodeIndex = history.episodeIndex;
    firstWhere.lineIndex = history.lineIndex;
    firstWhere.lastPlaybackAt = history.lastPlaybackAt;
    playback.add(firstWhere);
    playbackStr = playback.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_playback", playbackStr);
    return true;
  }

  /// 获取所有播放历史
  /// 返回播放历史列表
  static List<PlaybackHistory> getPlaybackHistory() {
    if (_prefs == null) return [];
    var playbackStr = _prefs!.getStringList("${_key}_playback") ?? [];
    return playbackStr
        .map((jsonStr) => PlaybackHistory.fromJson(json.decode(jsonStr)))
        .toList();
  }

  /// 根据 ID 获取订阅历史
  /// [id]: 订阅 ID
  /// 返回匹配的订阅历史，若不存在则返回 null
  static SubscribeHistory? getSubscribeHistoryById(int id) {
    if (_prefs == null) return null;
    final key = "${_key}_subscribe";
    var histories = _prefs!.getStringList(key) ?? [];
    List<SubscribeHistory> historyList = histories
        .map((jsonStr) => SubscribeHistory.fromJson(json.decode(jsonStr)))
        .toList();
    try {
      return historyList.firstWhere((history) => history.subId == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据 ID 获取播放历史
  /// [id]: 订阅 ID
  /// 返回匹配的播放历史，若不存在则返回 null
  static PlaybackHistory? getPlaybackHistoryById(int id) {
    if (_prefs == null) return null;
    final key = "${_key}_playback";
    var histories = _prefs!.getStringList(key) ?? [];
    List<PlaybackHistory> historyList = histories
        .map((jsonStr) => PlaybackHistory.fromJson(json.decode(jsonStr)))
        .toList();
    try {
      return historyList.firstWhere((history) => history.subId == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新订阅历史列表
  /// [histories]: 新的订阅历史列表
  static void updateSubscribeHistory(List<SubscribeHistory> histories) {
    if (_prefs == null) return;
    clearHistory(clearPlayback: false);
    var subsStr = histories.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_subscribe", subsStr);
  }

  /// 更新播放历史列表
  /// [histories]: 新的播放历史列表
  static void updatePlaybackHistory(List<PlaybackHistory> histories) {
    if (_prefs == null) return;
    clearHistory(clearPlayback: true);
    var playbackStr = histories
        .map((item) => json.encode(item.toJson()))
        .toList();
    _prefs!.setStringList("${_key}_playback", playbackStr);
  }

  /// 清除历史记录
  /// [clearPlayback]: 是否清除播放历史，默认为 true
  /// 如果为 false，则清除订阅历史
  static void clearHistory({bool clearPlayback = true}) {
    if (_prefs == null) return;
    if (clearPlayback) {
      _prefs!.remove("${_key}_playback");
    } else {
      _prefs!.remove("${_key}_subscribe");
    }
  }

  /// 获取搜索历史
  /// 返回搜索历史字符串列表
  static List<String> getSearchHistory() {
    if (_prefs == null) return [];
    return _prefs!.getStringList("${_key}_search") ?? [];
  }

  /// 移除所有搜索历史
  static void removeAllSearchHistory() {
    if (_prefs == null) return;
    _prefs!.remove("${_key}_search");
  }

  /// 保存搜索历史
  /// [history]: 搜索历史字符串列表
  static void saveSearchHistory(List<String> history) {
    if (_prefs == null) return;
    _prefs!.setStringList("${_key}_search", history);
  }

  /// 获取应用设置
  /// 返回应用设置对象，若不存在则返回默认设置
  static AppSetting getAppSetting() {
    if (_prefs == null) return AppSetting();
    var appSettingStr = _prefs!.getString("${_key}_app_setting") ?? "";
    if (appSettingStr.isEmpty) {
      return AppSetting();
    }
    return (AppSetting.fromJson(json.decode(appSettingStr)));
  }

  /// 保存应用设置
  /// [appSetting]: 应用设置对象
  /// [isSync]: 是否同步到服务器，默认为 true
  static void saveAppSetting(AppSetting appSetting, {bool isSync = true}) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_app_setting", json.encode(appSetting.toJson()));
    if (isSync) {
      SettingApi.saveSetting(appSetting, (_) {});
    }
  }

  /// 获取规则列表
  /// 返回规则对象列表
  static List<Rule> getRules() {
    if (_prefs == null) return [];
    var rulesStr = _prefs!.getStringList("${_key}_rules") ?? [];
    return rulesStr
        .map((jsonStr) => Rule.fromJson(json.decode(jsonStr)))
        .toList();
  }

  /// 保存规则列表
  /// [rules]: 规则对象列表
  /// 会自动去重，保留最新的规则
  static void saveRules(List<Rule> rules) {
    if (_prefs == null) return;
    var rulesStr = _prefs!.getStringList("${_key}_rules") ?? [];
    var ruleList = rulesStr
        .map((item) => Rule.fromJson(json.decode(item)))
        .toList();
    ruleList.addAll(rules);
    // 去重,根据name,保留最新的
    var ruleMap = <String, Rule>{};
    for (var rule in ruleList) {
      if (ruleMap[rule.name] != null) {
        if (ruleMap[rule.name]!.updateAt.isAfter(rule.updateAt)) {
          continue;
        }
      }
      ruleMap[rule.name] = rule;
    }
    rulesStr = ruleMap.values
        .map((item) => json.encode(item.toJson()))
        .toList();
    _prefs!.setStringList("${_key}_rules", rulesStr);
  }

  /// 根据名称移除规则
  /// [name]: 规则名称
  static void removeRuleByName(String name) {
    if (_prefs == null) return;
    var rulesStr = _prefs!.getStringList("${_key}_rules") ?? [];
    var rules = rulesStr
        .map((jsonStr) => Rule.fromJson(json.decode(jsonStr)))
        .toList();
    rules.removeWhere((item) => item.name == name);
    rulesStr = rules.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_rules", rulesStr);
  }

  /// 更新规则
  /// [rule]: 规则对象
  static void updateRule(Rule rule) {
    if (_prefs == null) return;
    var rulesStr = _prefs!.getStringList("${_key}_rules") ?? [];
    var rules = rulesStr
        .map((jsonStr) => Rule.fromJson(json.decode(jsonStr)))
        .toList();
    rules.removeWhere((item) => item.name == rule.name);
    rules.add(rule);
    rulesStr = rules.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_rules", rulesStr);
  }

  /// 保存规则仓库 URL
  /// [url]: 规则仓库 URL 字符串
  static void saveRuleRepositoryUrl(String url) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_rule_repository_url", url);
  }

  /// 获取规则仓库 URL
  /// 返回规则仓库 URL 字符串，若不存在则返回空字符串
  static String getRuleRepositoryUrl() {
    if (_prefs == null) return "";
    return _prefs!.getString("${_key}_rule_repository_url") ?? "";
  }

  /// 保存主题缓存和数据源
  /// [data]: 主题数据对象
  /// 返回操作是否成功
  static bool setSubjectCacheAndSource(Data data) {
    if (_prefs == null) return false;
    var dataListStr = _prefs!.getStringList("${_key}_data_source") ?? [];
    var dataList = dataListStr
        .map((item) => Data.fromJson(json.decode(item)))
        .toList();
    dataList.add(data);
    var dataMap = {};
    for (var item in dataList) {
      dataMap[item.id] = item;
    }
    dataListStr = dataMap.values
        .map((item) => json.encode(item.toJson()))
        .toList();
    _prefs!.setStringList("${_key}_data_cache", dataListStr);
    return true;
  }

  /// 根据订阅 ID 获取主题缓存和数据源
  /// [subId]: 订阅 ID
  /// 返回主题数据对象，若不存在则返回 null
  static Data? getSubjectCacheAndSource(int subId) {
    if (_prefs == null) return null;
    var dataListStr = _prefs!.getStringList("${_key}_data_cache") ?? [];
    if (dataListStr.isEmpty) {
      return null;
    }
    var dataList = dataListStr
        .map((item) => Data.fromJson(json.decode(item)))
        .toList();
    return dataList.where((item) => item.id == subId).firstOrNull;
  }

  /// 保存日历缓存
  /// [calendars]: 日历对象列表
  static void setCalendarCache(List<Calendar> calendars) {
    if (_prefs == null) return;
    var calendarsStr = _prefs!.getStringList("${_key}_calendar_cache") ?? [];
    calendarsStr.addAll(calendars.map((item) => json.encode(item.toJson())));
    _prefs!.setStringList("${_key}_calendar_cache", calendarsStr);
  }

  /// 获取日历缓存
  /// 返回日历对象列表
  static List<Calendar> getCalendarCache() {
    if (_prefs == null) return [];
    var calendarsStr = _prefs!.getStringList("${_key}_calendar_cache") ?? [];
    return calendarsStr
        .map((item) => Calendar.fromJson(json.decode(item)))
        .toList();
  }

  /// 保存首页热门缓存
  /// [s]: 主题对象
  static void setHomeHotCache(Subject s) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_home_hot_cache", json.encode(s.toJson()));
  }

  /// 获取首页热门缓存
  /// 返回主题对象，若不存在则返回 null
  static Subject? getHomeHotCache() {
    if (_prefs == null) return null;
    var homeCache = _prefs!.getString("${_key}_home_hot_cache");
    if (homeCache == null) return null;
    log("home->getHomeCache: get cache ok");
    return Subject.fromJson(json.decode(homeCache));
  }

  /// 保存首页排行榜缓存
  /// [s]: 主题对象
  static void setHomeRankCache(Subject s) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_home_rank_cache", json.encode(s.toJson()));
  }

  /// 获取首页排行榜缓存
  /// 返回主题对象，若不存在则返回 null
  static Subject? getHomeRankCache() {
    if (_prefs == null) return null;
    var homeCache = _prefs!.getString("${_key}_home_rank_cache");
    if (homeCache == null) return null;
    log("home->getHomeRankCache: get cache ok");
    return Subject.fromJson(json.decode(homeCache));
  }

  /// 获取背景图片路径
  /// 返回背景图片路径字符串，若不存在则返回空字符串
  static String getBackgroundImagePath() {
    if (_prefs == null) return "";
    return _prefs!.getString("${_key}_background_image_path") ?? "";
  }

  /// 设置背景图片路径
  /// [path]: 背景图片路径字符串
  static void setBackgroundImagePath(String path) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_background_image_path", path);
  }

  /// 获取布尔值
  /// [key]: 存储键
  /// [defaultValue]: 默认值，默认为 false
  /// 返回存储的布尔值，若不存在则返回默认值
  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs!.getBool("${_key}_$key") ?? defaultValue;
  }

  /// 获取整数值
  /// [key]: 存储键
  /// [defaultValue]: 默认值，默认为 0
  /// 返回存储的整数值，若不存在则返回默认值
  static int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  /// 获取浮点数值
  /// [key]: 存储键
  /// [defaultValue]: 默认值，默认为 1.0
  /// 返回存储的浮点数值，若不存在则返回默认值
  static double getDouble(String key, {double defaultValue = 1.0}) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  /// 获取字符串值
  /// [key]: 存储键
  /// [defaultValue]: 默认值，默认为空字符串
  /// 返回存储的字符串值，若不存在则返回默认值
  static String getString(String key, {String defaultValue = ""}) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  /// 设置布尔值
  /// [key]: 存储键
  /// [value]: 布尔值
  static void setBool(String key, bool value) {
    _prefs?.setBool(key, value);
  }

  /// 设置浮点数值
  /// [key]: 存储键
  /// [value]: 浮点数值
  static void setDouble(String key, double value) {
    _prefs?.setDouble(key, value);
  }

  /// 设置字符串值
  /// [key]: 存储键
  /// [value]: 字符串值
  static void setString(String key, String value) {
    _prefs?.setString(key, value);
  }

  /// 设置整数值
  /// [key]: 存储键
  /// [value]: 整数值
  static void setInt(String key, int value) {
    _prefs?.setInt(key, value);
  }
}