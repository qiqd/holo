import 'package:hive_ce/hive.dart';
import 'package:holo/entity/anime_info.dart';
import 'package:holo/entity/daily_broadcast.dart';
import 'package:holo/entity/image.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/entity/user_playback.dart';
import 'package:holo/entity/user_setting.dart';
import 'package:holo/entity/user_subscribe.dart';
import 'package:path_provider/path_provider.dart';

import '../entity/user.dart' show User, UserAdapter;

class HiveUtil {
  static User? user;
  static Box<User>? userBox;
  static Box<Rule>? ruleBox;
  static Box<UserSubscribe>? userSubscribeBox;
  static Box<UserPlayback>? userPlaybackBox;
  static Box<String>? userSearchBox;
  static Box<AnimeInfo>? AnimeInfoBox;
  static Box<UserSetting>? userSettingBox;
  static Box<AnimeInfo>? hotAnimeInfoBox;
  static Box<AnimeInfo>? hiScoreAnimeInfoBox;
  static Box<DailyBroadcast>? dailyBroadcastBox;
  static late String appDBPath;

  static Future<void> closeHive() async {
    await Hive.close();
  }

  /// 初始化Hive数据库
  static Future<void> initHive() async {
    await Hive.close();
    appDBPath = '${(await getApplicationDocumentsDirectory()).path}/holo';
    Hive.init(appDBPath);
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
      Hive.registerAdapter(UserAdapter());
    }
    userBox = await Hive.openBox("user");
    user = userBox?.values.firstOrNull;
    await Hive.close();
    if (user == null) {
      Hive.init('$appDBPath/common/');
    } else {
      Hive.init('$appDBPath/${user!.email}/');
    }
    if (!Hive.isAdapterRegistered(UserSubscribeAdapter().typeId)) {
      Hive.registerAdapter(UserSubscribeAdapter());
    }
    if (!Hive.isAdapterRegistered(UserPlaybackAdapter().typeId)) {
      Hive.registerAdapter(UserPlaybackAdapter());
    }
    if (!Hive.isAdapterRegistered(UserSettingAdapter().typeId)) {
      Hive.registerAdapter(UserSettingAdapter());
    }
    if (!Hive.isAdapterRegistered(AnimeInfoAdapter().typeId)) {
      Hive.registerAdapter(AnimeInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(RuleAdapter().typeId)) {
      Hive.registerAdapter(RuleAdapter());
    }
    if (!Hive.isAdapterRegistered(RequestMethodAdapter().typeId)) {
      Hive.registerAdapter(RequestMethodAdapter());
    }
    if (!Hive.isAdapterRegistered(ImageAdapter().typeId)) {
      Hive.registerAdapter(ImageAdapter());
    }
    if (!Hive.isAdapterRegistered(DailyBroadcastAdapter().typeId)) {
      Hive.registerAdapter(DailyBroadcastAdapter());
    }

    ruleBox = await Hive.openBox<Rule>("rule");
    userSettingBox = await Hive.openBox<UserSetting>("user_setting");
    userSubscribeBox = await Hive.openBox<UserSubscribe>("user_subscribe");
    userPlaybackBox = await Hive.openBox<UserPlayback>("user_playback");
    userSearchBox = await Hive.openBox<String>("user_search");
    AnimeInfoBox = await Hive.openBox<AnimeInfo>("subject_item");
    hotAnimeInfoBox = await Hive.openBox<AnimeInfo>("hot_subject_item");
    hiScoreAnimeInfoBox = await Hive.openBox<AnimeInfo>(
      "hi_score_subject_item",
    );
    dailyBroadcastBox = await Hive.openBox<DailyBroadcast>("daily_broadcast");
  }

  /// 获取用户订阅路径，必须在[initHive]方法后调用
  static String getUserSubscribePath() {
    return '$appDBPath/${user?.email}/user_subscribe.hive';
  }

  /// 获取用户播放放路径，必须在[initHive]方法后调用
  static String getUserPlaybackPath() {
    return '$appDBPath/${user?.email}/user_playback.hive';
  }

  /// 获取用户设置路径，必须在[initHive]方法后调用
  static String getUserSettingPath() {
    return '$appDBPath/${user?.email}/user_setting.hive';
  }

  /// 获取公共用户订阅路径，必须在[initHive]方法后调用
  static String getCommonUserSubscribePath() {
    return '$appDBPath/common/user_subscribe.hive';
  }

  /// 获取公共用户播放放路径，必须在[initHive]方法后调用
  static String getCommonUserPlaybackPath() {
    return '$appDBPath/common/user_playback.hive';
  }

  /// 获取公共用户设置路径，必须在[initHive]方法后调用
  static String getCommonUserSettingPath() {
    return '$appDBPath/common/user_setting.hive';
  }

  /// 获取公共用户数据路径，必须在[initHive]方法后调用
  static List<String> getCommonUserDataPath() {
    String subscribePath = '$appDBPath/common/user_subscribe.hive';
    String playbackPath = '$appDBPath/common/user_playback.hive';
    String settingPath = '$appDBPath/common/user_setting.hive';
    return [subscribePath, playbackPath, settingPath];
  }

  static Future<void> setUser(User user) async {
    await Hive.close();
    Hive.init('${(await getApplicationDocumentsDirectory()).path}/holo');
    userBox = await Hive.openBox("user");
    await userBox?.clear();
    await userBox?.add(user);
    await Hive.close();
  }

  static Future<void> removeUser() async {
    await Hive.close();
    Hive.init('${(await getApplicationDocumentsDirectory()).path}/holo');
    userBox = await Hive.openBox("user");
    await userBox?.clear();
  }

  static Future<void> setRule(Rule rule) async {
    var rules = getRules();
    rules.removeWhere((element) => element.name == rule.name);
    rules.add(rule);
    await ruleBox?.clear();
    await ruleBox?.addAll(rules);
  }

  static List<Rule> getRules() {
    return ruleBox?.values.toList() ?? [];
  }

  /// 清除规则
  /// [name] 规则名称
  /// 如果[name]为null，则清除所有规则
  static Future<void> clearRule({String? name}) async {
    if (name == null) {
      await ruleBox?.clear();
    } else {
      var list = getRules();
      list.removeWhere((element) => element.name == name);
      await ruleBox?.clear();
      await ruleBox?.addAll(list);
    }
  }

  /// 设置用户订阅
  /// [userSubscribes] 用户订阅列表
  /// 如果[userSubscribes]为空， 返回当前订阅列表
  /// 否则，根据订阅id更新订阅列表，添加新订阅
  /// 返回设置后的订阅列表
  static Future<List<UserSubscribe>> setUserSubscribes(
    List<UserSubscribe> userSubscribes,
  ) async {
    var ids = userSubscribes.map((e) => e.id).toList();
    var newList = getUserSubscribes();
    if (ids.isEmpty) {
      return newList;
    }
    newList.removeWhere((element) => ids.contains(element.id));
    newList.addAll(userSubscribes);
    await userSubscribeBox?.clear();
    await userSubscribeBox?.addAll(newList);
    return newList;
  }

  /// 获取用户订阅
  /// [id] 订阅id
  /// 如果[id]为null，则获取所有订阅
  static List<UserSubscribe> getUserSubscribes({int? id}) {
    if (id == null) {
      return userSubscribeBox?.values.toList() ?? [];
    }
    return userSubscribeBox?.values
            .toList()
            .where((element) => element.id == id)
            .toList() ??
        [];
  }

  /// 删除用户订阅
  /// [ids] 订阅id列表
  /// 如果[ids]为空，则清除所有订阅
  /// 返回清除后的订阅列表
  static Future<List<UserSubscribe>> clearUserSubscribe({
    List<int> ids = const [],
  }) async {
    if (ids.isEmpty) {
      await userSubscribeBox?.clear();
      return [];
    } else {
      var list = getUserSubscribes();
      list.removeWhere((element) => ids.contains(element.id));
      await userSubscribeBox?.clear();
      await userSubscribeBox?.addAll(list);
      return list;
    }
  }

  /// 设置用户播放记录
  /// [userPlaybacks] 用户播放记录列表
  /// 如果[userPlaybacks]为空， 返回当前播放记录列表
  /// 否则，根据播放记录id更新播放记录列表，添加新播放记录
  /// 返回设置后的播放记录列表
  static Future<List<UserPlayback>> setUserPlaybacks(
    List<UserPlayback> userPlaybacks,
  ) async {
    var ids = userPlaybacks.map((e) => e.id).toList();
    var newList = getUserPlaybacks();
    if (ids.isEmpty) {
      return newList;
    }
    newList.removeWhere((element) => ids.contains(element.id));
    newList.addAll(userPlaybacks);
    await userPlaybackBox?.clear();
    await userPlaybackBox?.addAll(newList);
    return newList;
  }

  static List<UserPlayback> getUserPlaybacks({int? id}) {
    if (id == null) {
      return userPlaybackBox?.values.toList() ?? [];
    }
    return userPlaybackBox?.values
            .toList()
            .where((element) => element.id == id)
            .toList() ??
        [];
  }

  /// 清除用户播放记录
  /// [ids] 播放记录id列表
  /// 如果[ids]为空，则清除所有播放记录
  /// 返回清除后的播放记录列表
  static Future<List<UserPlayback>> clearUserPlayback({
    List<int> ids = const [],
  }) async {
    if (ids.isEmpty) {
      await userPlaybackBox?.clear();
      return [];
    } else {
      var list = getUserPlaybacks();
      list.removeWhere((element) => ids.contains(element.id));
      await userPlaybackBox?.clear();
      await userPlaybackBox?.addAll(list);
      return list;
    }
  }

  static Future<void> setUserSearch(String keyword) async {
    var list = getUserSearches();
    list.add(keyword);
    await userSearchBox?.clear();
    await userSearchBox?.addAll(list.toList());
  }

  static List<String> getUserSearches() {
    return userSearchBox?.values.toList() ?? [];
  }

  /// 清除用户搜索记录
  /// [keyword] 搜索关键词
  /// 如果[keyword]为null，则清除所有搜索记录
  static Future<void> clearUserSearches({String? keyword}) async {
    if (keyword == null) {
      await userSearchBox?.clear();
    } else {
      var list = getUserSearches();
      list.remove(keyword);
      await userSearchBox?.clear();
      await userSearchBox?.addAll(list);
    }
  }

  static Future<UserSetting> setUserSetting(UserSetting userSetting) async {
    //LoggerUtil.logger.i("setUserSetting: $userSetting");
    await userSettingBox?.clear();
    await userSettingBox?.add(userSetting);
    return userSetting;
  }

  /// 获取用户设置
  /// 如果用户设置不存在，则返回默认用户设置
  static UserSetting getUserSetting() {
    return userSettingBox?.values.toList().firstOrNull ??
        UserSetting.createDefaultUserSetting(email: user?.email ?? "");
  }

  static Future<void> clearUserSetting() async {
    await userSettingBox?.clear();
  }

  static Future<void> setAnimeInfo(AnimeInfo AnimeInfo) async {
    var newList =
        AnimeInfoBox?.values
            .where((item) => item.id != AnimeInfo.id)
            .toList() ??
        [];
    newList.add(AnimeInfo);
    await AnimeInfoBox?.clear();
    await AnimeInfoBox?.addAll(newList);
  }

  static AnimeInfo? getAnimeInfoById(int id) {
    return AnimeInfoBox?.values
        .toList()
        .where((element) => element.id == id)
        .firstOrNull;
  }

  static Future<void> setHotAnimeInfo(List<AnimeInfo> animeInfoList) async {
    await hotAnimeInfoBox?.clear();
    await hotAnimeInfoBox?.addAll(animeInfoList);
  }

  static List<AnimeInfo> getHotAnimeInfos() {
    return hotAnimeInfoBox?.values.toList() ?? [];
  }

  static Future<void> setHiScoreAnimeInfo(List<AnimeInfo> animeInfoList) async {
    await hiScoreAnimeInfoBox?.clear();
    await hiScoreAnimeInfoBox?.addAll(animeInfoList);
  }

  static List<AnimeInfo> getHiScoreAnimeInfos() {
    return hiScoreAnimeInfoBox?.values.toList() ?? [];
  }

  static Future<void> setDailyBroadcast(
    List<DailyBroadcast> dailyBroadcast,
  ) async {
    await dailyBroadcastBox?.clear();
    await dailyBroadcastBox?.addAll(dailyBroadcast);
  }

  static List<DailyBroadcast> getDailyBroadcast() {
    return dailyBroadcastBox?.values.toList() ?? [];
  }
}
