import 'dart:convert';

import 'package:mobile_holo/entity/history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_holo/api/record_api.dart' show RecordApi;

class LocalStore {
  static const String _key = "holo_local_store";
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    RecordApi.initServer();
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

  static void addHistory(History history, {bool isPlaybackHistory = true}) {
    if (_prefs == null) return;
    Map<int, History> idToHistory = {};
    if (isPlaybackHistory) {
      var histories = _prefs!.getStringList("${_key}_playback") ?? [];
      List<History> historyList = histories
          .map((jsonStr) => History.fromJson(json.decode(jsonStr)))
          .toList();
      historyList.add(history);
      for (var item in historyList) {
        if (!idToHistory.containsKey(item.id) ||
            item.lastViewAt == null ||
            item.lastViewAt!.isAfter(
              idToHistory[item.id]!.lastViewAt ?? DateTime(1980),
            )) {
          idToHistory[item.id] = item;
        }
      }
    } else {
      var histories = _prefs!.getStringList("${_key}_subscribe") ?? [];
      List<History> historyList = histories
          .map((jsonStr) => History.fromJson(json.decode(jsonStr)))
          .toList();
      historyList.add(history);
      for (var item in historyList) {
        if (!idToHistory.containsKey(item.id) ||
            item.lastSubscribeAt == null ||
            item.lastSubscribeAt!.isAfter(
              idToHistory[item.id]!.lastSubscribeAt ?? DateTime(1980),
            )) {
          idToHistory[item.id] = item;
        }
      }
    }
    List<String> updatedHistories = idToHistory.values
        .map((item) => json.encode(item.toJson()))
        .toList();
    final key = isPlaybackHistory ? "${_key}_playback" : "${_key}_subscribe";
    _prefs!.setStringList(key, updatedHistories);
  }

  static History? getHistoryById(int id, {bool isPlaybackHistory = true}) {
    if (_prefs == null) return null;
    final key = isPlaybackHistory ? "${_key}_playback" : "${_key}_subscribe";
    var histories = _prefs!.getStringList(key) ?? [];
    List<History> historyList = histories
        .map((jsonStr) => History.fromJson(json.decode(jsonStr)))
        .toList();
    try {
      return historyList.firstWhere((history) => history.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<History> gerAllHistory() {
    if (_prefs == null) return [];
    var h2 = _prefs!.getStringList("${_key}_subscribe") ?? [];
    var h3 = _prefs!.getStringList("${_key}_playback") ?? [];
    var histories = [...h2, ...h3];
    return histories
        .map((jsonStr) => History.fromJson(json.decode(jsonStr)))
        .toList();
  }

  static void deleteHistoryById(int id) {
    if (_prefs == null) return;
    var histories = _prefs!.getStringList(_key) ?? [];
    List<History> historyList = histories
        .map((jsonStr) => History.fromJson(json.decode(jsonStr)))
        .toList();
    historyList.removeWhere((history) => history.id == id);
    List<String> updatedHistories = historyList
        .map((item) => json.encode(item.toJson()))
        .toList();
    _prefs!.setStringList(_key, updatedHistories);
  }

  static void clearHistory() {
    if (_prefs == null) return;
    _prefs!.remove("${_key}_playback");
    _prefs!.remove("${_key}_subscribe");
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

  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs!.getBool(key) ?? defaultValue;
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
