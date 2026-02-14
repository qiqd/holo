import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:holo/util/local_store.dart';
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
  List<PlaybackHistory> playback = [];
  List<SubscribeHistory> subscribe = [];
  List<SubscribeHistory> wish = [];
  List<SubscribeHistory> watching = [];
  List<SubscribeHistory> watched = [];
  bool _isEditMode = false;
  final Set<int> _checkedPlaybackIds = {};
  final Set<int> _checkedSubscribeIds = {};
  bool _isUpdating = false;
  late final TabController _tabController = TabController(
    vsync: this,
    length: 5,
  );
  Future<void> _fetchPlaybackHistoryFromServer() async {
    final records = await PlayBackApi.fetchPlaybackHistory((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("subscribe.fetch_subs_failed"))),
      );
    });
    if (records.isNotEmpty) {
      setState(() {
        playback = records;
        playback.sort((a, b) => b.lastPlaybackAt.compareTo(a.lastPlaybackAt));
        LocalStore.updatePlaybackHistory(records);
      });
    }
  }

  Future<void> _fetchSubscribeHistoryFromServer() async {
    final records = await SubscribeApi.fetchSubscribeHistory((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("subscribe.fetch_view_failed"))),
      );
    });
    if (records.isNotEmpty) {
      setState(() {
        subscribe = records;
        subscribe.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        wish = records.where((item) => item.viewingStatus == 1).toList();
        watching = records.where((item) => item.viewingStatus == 3).toList();
        watched = records.where((item) => item.viewingStatus == 2).toList();
        LocalStore.updateSubscribeHistory(records);
      });
    }
  }

  void _loadHistory() {
    final playbackHistory = LocalStore.getPlaybackHistory();
    final subscribeHistory = LocalStore.getSubscribeHistory();
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

  Data? _getCacheBySubId(int id) {
    return LocalStore.getSubjectCacheAndSource(id);
  }

  void _deletePlaybackHistory() {
    _checkedPlaybackIds.toList().forEach((id) {
      LocalStore.removePlaybackHistoryBySubId(id);
      PlayBackApi.deletePlaybackRecordBySubId(id, () {}, (_) {});
    });
    _loadHistory();
  }

  void _changeSubscribeHistory(int viewingStatus) {
    subscribe
        .where((item) => _checkedSubscribeIds.contains(item.subId))
        .forEach((s) {
          switch (viewingStatus) {
            case -1:
              LocalStore.removeSubscribeHistoryBySubId(s.subId);
              SubscribeApi.deleteSubscribeRecordBySubId(s.subId, () {}, (_) {});
              break;
            default:
              s.viewingStatus = viewingStatus;
              LocalStore.addSubscribeHistory(s);
          }
        });
    _checkedSubscribeIds.clear();
    _loadHistory();
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
      onMsgTab: () async {
        isPlayback
            ? await _fetchPlaybackHistoryFromServer()
            : await _fetchSubscribeHistoryFromServer();
      },
    );
  }

  Widget _buildTabbarView({
    List<SubscribeHistory> s = const [],
    List<PlaybackHistory> p = const [],
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
                    showRating: false,
                    id: "subscribe_${item.subId}",
                    imageUrl: item.imgUrl,
                    title: item.title,
                    isChecked: _checkedSubscribeIds.contains(item.subId),
                    showCheckBox: _isEditMode,
                    onTap: () {
                      if (_isEditMode) {
                        setState(() {
                          _checkedSubscribeIds.contains(item.subId)
                              ? _checkedSubscribeIds.remove(item.subId)
                              : _checkedSubscribeIds.add(item.subId);
                        });
                      } else {
                        var cache = _getCacheBySubId(item.subId);
                        context.push(
                          '/detail',
                          extra: {
                            "id": item.subId,
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
              onRefresh: () async {
                await _fetchSubscribeHistoryFromServer();
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
                    id: "subscribe.history_${item.subId}",
                    imageUrl: item.imgUrl,
                    title: item.title,
                    isChecked: _checkedPlaybackIds.contains(item.subId),
                    showCheckbox: _isEditMode,
                    onTap: () {
                      if (_isEditMode) {
                        setState(() {
                          _checkedPlaybackIds.contains(item.subId)
                              ? _checkedPlaybackIds.remove(item.subId)
                              : _checkedPlaybackIds.add(item.subId);
                        });
                      } else {
                        var cache = _getCacheBySubId(item.subId);
                        context.push(
                          '/detail',
                          extra: {
                            "id": item.subId,
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
                await _fetchPlaybackHistoryFromServer();
              },
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    initTabBarListener();
    _loadHistory();
    _fetchPlaybackHistoryFromServer();
    _fetchSubscribeHistoryFromServer();
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        actionsPadding: .symmetric(horizontal: 12),
        title: Text(tr("subscribe.title")),
        actions: [
          if (_checkedSubscribeIds.isNotEmpty)
            PopupMenuButton(
              icon: Icon(Icons.menu_rounded),
              itemBuilder: (context) => [
                PopupMenuItem(value: 1, child: Text("想看")),
                PopupMenuItem(value: 3, child: Text("在看")),
                PopupMenuItem(value: 2, child: Text("看过")),
                PopupMenuItem(value: -1, child: Text("取消")),
              ],
              onSelected: (value) {
                _changeSubscribeHistory(value);
              },
            ),

          if (_checkedPlaybackIds.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _deletePlaybackHistory();
                });
              },
            ),
          IconButton(
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
                await _fetchPlaybackHistoryFromServer();
                await _fetchSubscribeHistoryFromServer();
                setState(() {
                  _isUpdating = false;
                });
              },
              icon: Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),

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
              tabAlignment: .center,
              dividerHeight: 0,
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
              child: TabBarView(
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
                      : _buildTabbarView(s: watched, isLandscape: isLandscape),
                  //在看
                  watching.isEmpty
                      ? SizedBox.shrink()
                      : _buildTabbarView(s: watching, isLandscape: isLandscape),
                  //播放历史部分
                  playback.isEmpty
                      ? _buildEmptyMsg(
                          tr("subscribe.refresh_btn_playback"),
                          isPlayback: true,
                        )
                      : _buildTabbarView(p: playback, isLandscape: isLandscape),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
