import 'dart:convert';

import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const String _key = "holo_local_store";
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getServerUrl() {
    return _prefs!.getString("${_key}_server_url");
  }

  static void setServerUrl(String serverUrl) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_server_url", serverUrl);
  }

  static String? getToken() {
    return _prefs!.getString("${_key}_token");
  }

  static void setToken(String token) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_token", token);
  }

  static String? getEmail() {
    if (_prefs == null) return null;
    return _prefs!.getString("${_key}_email");
  }

  static void setEmail(String email) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_email", email);
  }

  static void removeLocalAccount() {
    if (_prefs == null) return;
    _prefs!.remove("${_key}_token");
    _prefs!.remove("${_key}_email");
    _prefs!.remove("${_key}_server_url");
  }

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

  static void addSubscribeHistory(SubscribeHistory history) {
    if (_prefs == null) return;
    var subsStr = _prefs!.getStringList("${_key}_subscribe") ?? [];
    var subs = subsStr
        .map((jsonStr) => SubscribeHistory.fromJson(json.decode(jsonStr)))
        .toList();
    var firstWhere = subs.firstWhere(
      (item) => item.subId == history.subId,
      orElse: () => SubscribeHistory(
        id: history.id,
        subId: history.subId,
        title: history.title,
        imgUrl: history.imgUrl,
        airDate: history.airDate,
        createdAt: history.createdAt,
        isSync: history.isSync,
      ),
    );
    subs.removeWhere((item) => item.subId == history.subId);
    subs.add(firstWhere);
    subsStr = subs.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_subscribe", subsStr);
  }

  static List<SubscribeHistory> getSubscribeHistory() {
    if (_prefs == null) return [];
    var subsStr = _prefs!.getStringList("${_key}_subscribe") ?? [];
    return subsStr
        .map((jsonStr) => SubscribeHistory.fromJson(json.decode(jsonStr)))
        .toList();
  }

  static void addPlaybackHistory(PlaybackHistory history) {
    if (_prefs == null) return;
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
  }

  static List<PlaybackHistory> getPlaybackHistory() {
    if (_prefs == null) return [];
    var playbackStr = _prefs!.getStringList("${_key}_playback") ?? [];
    return playbackStr
        .map((jsonStr) => PlaybackHistory.fromJson(json.decode(jsonStr)))
        .toList();
  }

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

  // static void deleteHistoryById(int id) {
  //   if (_prefs == null) return;
  //   var histories = _prefs!.getStringList(_key) ?? [];
  //   List<History> historyList = histories
  //       .map((jsonStr) => History.fromJson(json.decode(jsonStr)))
  //       .toList();
  //   historyList.removeWhere((history) => history.id == id);
  //   List<String> updatedHistories = historyList
  //       .map((item) => json.encode(item.toJson()))
  //       .toList();
  //   _prefs!.setStringList(_key, updatedHistories);
  // }
  static void updateSubscribeHistory(List<SubscribeHistory> histories) {
    if (_prefs == null) return;
    clearHistory(clearPlayback: false);
    var subsStr = histories.map((item) => json.encode(item.toJson())).toList();
    _prefs!.setStringList("${_key}_subscribe", subsStr);
  }

  static void updatePlaybackHistory(List<PlaybackHistory> histories) {
    if (_prefs == null) return;
    clearHistory(clearPlayback: true);
    var playbackStr = histories
        .map((item) => json.encode(item.toJson()))
        .toList();
    _prefs!.setStringList("${_key}_playback", playbackStr);
  }

  static void clearHistory({bool clearPlayback = true}) {
    if (_prefs == null) return;
    if (clearPlayback) {
      _prefs!.remove("${_key}_playback");
    } else {
      _prefs!.remove("${_key}_subscribe");
    }
  }

  static List<String> getSearchHistory() {
    if (_prefs == null) return [];
    return _prefs!.getStringList("${_key}_search") ?? [];
  }

  static void removeAllSearchHistory() {
    if (_prefs == null) return;
    _prefs!.remove("${_key}_search");
  }

  static void saveSearchHistory(List<String> history) {
    if (_prefs == null) return;
    _prefs!.setStringList("${_key}_search", history);
  }

  static Map<String, dynamic>? getDanmakuOption() {
    if (_prefs == null) return null;
    var danmakuOptionStr = _prefs!.getString("${_key}_danmaku_option") ?? "";
    if (danmakuOptionStr.isEmpty) {
      return {"option": DanmakuOption(), "filter": ""};
    }
    var map = json.decode(danmakuOptionStr) as Map<String, dynamic>;
    final option = DanmakuOption(
      opacity: map["opacity"] as double,
      area: map["area"] as double,
      fontSize: map["fontSize"] as double,
      hideTop: map["hideTop"] as bool,
      hideBottom: map["hideBottom"] as bool,
      hideScroll: map["hideScroll"] as bool,
      massiveMode: map["massiveMode"] as bool,
    );
    return {"option": option, "filter": map["filter"] as String};
  }

  static void saveDanmakuOption(DanmakuOption option, {String filter = ""}) {
    if (_prefs == null) return;
    final map = {
      "opacity": option.opacity,
      "area": option.area,
      "fontSize": option.fontSize,
      "hideTop": option.hideTop,
      "hideBottom": option.hideBottom,
      "hideScroll": option.hideScroll,
      "massiveMode": option.massiveMode,
      "filter": filter,
    };
    _prefs!.setString("${_key}_danmaku_option", json.encode(map));
  }

  static List<Rule> getRules() {
    if (_prefs == null) return [];
    var rulesStr = _prefs!.getStringList("${_key}_rules") ?? [];
    return rulesStr
        .map((jsonStr) => Rule.fromJson(json.decode(jsonStr)))
        .toList();
  }

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

  static void saveRuleRepositoryUrl(String url) {
    if (_prefs == null) return;
    _prefs!.setString("${_key}_rule_repository_url", url);
  }

  static String getRuleRepositoryUrl() {
    if (_prefs == null) return "";
    return _prefs!.getString("${_key}_rule_repository_url") ?? "";
  }

  static bool getUseSystemColor() {
    return _prefs!.getBool("${_key}_use_system_color") ?? false;
  }

  static void setUseSystemColor(bool value) {
    _prefs?.setBool("${_key}_use_system_color", value);
  }

  static void setSubjectCacheAndSource(Data data) {
    if (_prefs == null) return;
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
  }

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

  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs!.getBool("${_key}_$key") ?? defaultValue;
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  static double getDouble(String key, {double defaultValue = 1.0}) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  static String getString(String key, {String defaultValue = ""}) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  static void setBool(String key, bool value) {
    _prefs?.setBool(key, value);
  }

  static void setDouble(String key, double value) {
    _prefs?.setDouble(key, value);
  }

  static void setString(String key, String value) {
    _prefs?.setString(key, value);
  }

  static void setInt(String key, int value) {
    _prefs?.setInt(key, value);
  }
}
