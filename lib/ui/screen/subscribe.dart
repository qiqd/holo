import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/web_dav.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/entity/user_playback.dart';
import 'package:holo/entity/user_subscribe.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:holo/main.dart';
import 'package:holo/util/hive_util.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final setting = MyApp.userSettingNotifier.value;
  List<UserPlayback> playback = [];
  List<UserSubscribe> subscribe = [];
  List<UserSubscribe> wish = [];
  List<UserSubscribe> watching = [];
  List<UserSubscribe> watched = [];
  bool _isEditMode = false;
  final Set<int> _checkedPlaybackIds = {};
  final Set<int> _checkedSubscribeIds = {};
  bool _isUpdating = false;
  late final TabController _tabController = TabController(
    vsync: this,
    length: 5,
  );

  Future<void> _fetchHistoryData() async {
    final success = await WebDAV.fetchData();
    if (success == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("WebDAV is not configured")));
      return;
    }
    if (success == true) {
      // HiveUtil.init();
      // WebDAV.init(HiveUtil.user);
      _loadHistory();
    } else if (success == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("subscribe.fetch_subs_failed"))),
      );
    }
  }

  void _loadHistory() {
    final playbackHistory = HiveUtil.getUserPlaybacks();
    final subscribeHistory = HiveUtil.getUserSubscribes();
    safeSetState(() {
      playback = playbackHistory;
      subscribe = subscribeHistory;
      playback.sort((a, b) => b.lastPlaybackAt.compareTo(a.lastPlaybackAt));
      subscribe.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      wish = subscribe.where((item) => item.viewingStatus == 1).toList();
      watching = subscribe.where((item) => item.viewingStatus == 3).toList();
      watched = subscribe.where((item) => item.viewingStatus == 2).toList();
    });
  }

  SubjectItem? _getCacheBySubId(int id) {
    return HiveUtil.getSubjectItemById(id);
  }

  Future<void> _deletePlaybackHistory() async {
    var futures = _checkedPlaybackIds.toList().map((id) {
      return HiveUtil.clearUserPlayback(id: id);
    }).toList();
    await Future.wait(futures);
    _loadHistory();
    if (MyApp.userSettingNotifier.value.email.isNotEmpty) {
      await WebDAV.syncData(false);
    }
  }

  Future<void> _changeSubscribeHistory(int viewingStatus) async {
    subscribe.where((item) => _checkedSubscribeIds.contains(item.id)).forEach((
      s,
    ) async {
      switch (viewingStatus) {
        // 删除订阅
        case -1:
          await HiveUtil.clearUserSubscribe(id: s.id);
          break;
        // 更新订阅状态
        default:
          var newSubscribe = s.copyWith(viewingStatus: viewingStatus);
          await HiveUtil.setUserSubscribe(newSubscribe);
      }
    });
    _checkedSubscribeIds.clear();
    _loadHistory();
    if (MyApp.userSettingNotifier.value.email.isNotEmpty) {
      await WebDAV.syncData(false);
    }
  }

  void initTabBarListener() {
    _tabController.addListener(() {
      setState(() {
        _isEditMode = false;
        _checkedSubscribeIds.clear();
        _checkedPlaybackIds.clear();
      });
    });
  }

  Widget _buildEmptyMsg(String msg, {bool isPlayback = false}) {
    return LoadingOrShowMsg(
      msg: msg,
      onMsgTab: () async => await _fetchHistoryData(),
    );
  }

  Widget _buildTabbarView({
    List<UserSubscribe> s = const [],
    List<UserPlayback> p = const [],
    bool isLandscape = false,
  }) {
    return SizedBox.expand(
      child: s.isNotEmpty
          // 订阅列表
          ? RefreshIndicator(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: s.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isLandscape ? 6 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  final item = s[index];
                  return MediaGrid(
                    id: "subscribe_${item.id}",
                    imageUrl: item.imgUrl,
                    title: item.title,
                    isChecked: _checkedSubscribeIds.contains(item.id),
                    showCheckBox: _isEditMode,
                    onTap: () {
                      if (_isEditMode) {
                        setState(() {
                          _checkedSubscribeIds.contains(item.id)
                              ? _checkedSubscribeIds.remove(item.id)
                              : _checkedSubscribeIds.add(item.id);
                        });
                      } else {
                        var cache = _getCacheBySubId(item.id);
                        context.push(
                          '/detail',
                          extra: {
                            "id": item.id,
                            "keyword": item.title,
                            "cover": item.imgUrl,
                            "from": "subscribe",
                            'subject': cache,
                          },
                        );
                      }
                    },
                  );
                },
              ),
              onRefresh: () {
                return _fetchHistoryData();
              },
            )
          // 播放记录列表
          : RefreshIndicator(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: p.length,
                itemBuilder: (context, index) {
                  final item = p[index];
                  return MediaCard(
                    height:
                        (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS)
                        ? 240
                        : 190,
                    lastViewAt: item.lastPlaybackAt,
                    historyEpisode: item.episodeIndex,
                    id: "subscribe.history_${item.id}",
                    imageUrl: item.imgUrl,
                    title: item.title,
                    isChecked: _checkedPlaybackIds.contains(item.id),
                    showCheckbox: _isEditMode,
                    onTap: () {
                      if (_isEditMode) {
                        setState(() {
                          _checkedPlaybackIds.contains(item.id)
                              ? _checkedPlaybackIds.remove(item.id)
                              : _checkedPlaybackIds.add(item.id);
                        });
                      } else {
                        var cache = _getCacheBySubId(item.id);
                        context.push(
                          '/detail',
                          extra: {
                            "id": item.id,
                            "keyword": item.title,
                            "cover": item.imgUrl,
                            "from": "subscribe.history",
                            'subject': cache,
                          },
                        );
                      }
                    },
                  );
                },
              ),
              onRefresh: () async {
                await _fetchHistoryData();
              },
            ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      actionsPadding: .symmetric(horizontal: 12),
      title: Text(tr("subscribe.title")),
      actions: [
        if (_checkedSubscribeIds.isNotEmpty)
          PopupMenuButton(
            tooltip: "Change Subscribe Status",
            icon: Icon(Icons.menu_rounded),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text('subscribe.tab_subs_wish'.tr()),
              ),
              PopupMenuItem(
                value: 3,
                child: Text('subscribe.tab_subs_watching'.tr()),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('subscribe.tab_subs_watched'.tr()),
              ),
              PopupMenuItem(
                value: -1,
                child: Text('common.dialog.cancel'.tr()),
              ),
            ],
            onSelected: (value) {
              _changeSubscribeHistory(value);
            },
          ),

        if (_checkedPlaybackIds.isNotEmpty)
          IconButton(
            tooltip: "Delete Playback History",
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _deletePlaybackHistory();
              });
            },
          ),
        IconButton(
          tooltip: "Toggle Edit Mode",
          icon: Icon(_isEditMode ? Icons.done_all : Icons.edit_rounded),
          onPressed: () {
            setState(() {
              _isEditMode = !_isEditMode;
              if (!_isEditMode) {
                _checkedPlaybackIds.clear();
                _checkedSubscribeIds.clear();
              }
            });
          },
        ),
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) ...[
          IconButton(
            tooltip: 'Refresh All',
            onPressed: () async {
              setState(() {
                _isUpdating = true;
              });
              await _fetchHistoryData();
              setState(() {
                _isUpdating = false;
              });
            },
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    initTabBarListener();
    _loadHistory();
    _fetchHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar() as PreferredSizeWidget,
      body: VisibilityDetector(
        key: const Key('subscribe_screen'),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction > 0) {
            _loadHistory();
          }
        },
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: .center,
              controller: _tabController,
              tabs: [
                Tab(text: tr("subscribe.tab_subs_all")),
                Tab(text: tr("subscribe.tab_subs_wish")),
                Tab(text: tr("subscribe.tab_subs_watched")),
                Tab(text: tr("subscribe.tab_subs_watching")),
                Tab(text: tr("subscribe.tab_playback")),
              ],
            ),
            if (_isUpdating) const LinearProgressIndicator(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      //全部
                      subscribe.isEmpty
                          ? _buildEmptyMsg(tr("subscribe.refresh_btn_subs"))
                          : _buildTabbarView(
                              s: subscribe,
                              isLandscape: isLandscape,
                            ),
                      //想看
                      wish.isEmpty
                          ? SizedBox.shrink()
                          : _buildTabbarView(s: wish, isLandscape: isLandscape),
                      //看过
                      watched.isEmpty
                          ? SizedBox.shrink()
                          : _buildTabbarView(
                              s: watched,
                              isLandscape: isLandscape,
                            ),
                      //在看
                      watching.isEmpty
                          ? SizedBox.shrink()
                          : _buildTabbarView(
                              s: watching,
                              isLandscape: isLandscape,
                            ),
                      //播放历史部分
                      playback.isEmpty
                          ? _buildEmptyMsg(
                              tr("subscribe.refresh_btn_playback"),
                              isPlayback: true,
                            )
                          : _buildTabbarView(
                              p: playback,
                              isLandscape: isLandscape,
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
