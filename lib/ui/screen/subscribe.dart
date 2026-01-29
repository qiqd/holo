import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/entity/subscribe_history.dart';
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
  final Set<int> _deleteModeIds = {};
  late final TabController _tabController = TabController(
    vsync: this,
    length: 2,
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
        LocalStore.updateSubscribeHistory(records);
      });
    }
  }

  void _loadHistory() {
    final playbackHistory = LocalStore.getPlaybackHistory();
    playback = playbackHistory;
    final subscribeHistory = LocalStore.getSubscribeHistory();
    subscribe = subscribeHistory;
    playback.sort((a, b) => b.lastPlaybackAt.compareTo(a.lastPlaybackAt));
    subscribe.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {});
  }

  Data? _getCacheBySubId(int id) {
    return LocalStore.getSubjectCacheAndSource(id);
  }

  void _deletePlaybackHistory(int id) {
    try {
      LocalStore.removePlaybackHistoryBySubId(id);
      PlayBackApi.deletePlaybackRecordBySubId(
        id,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("subscribe.delete_view_success"))),
          );
        },
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("subscribe.delete_view_failed"))),
          );
        },
      );

      setState(() {
        playback.removeWhere((item) => item.subId == id);
        _deleteModeIds.remove(id);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("subscribe.delete_failed"))));
    }
  }

  void _deleteSubscribeHistory(int id) {
    try {
      LocalStore.removeSubscribeHistoryBySubId(id);
      SubscribeApi.deleteSubscribeRecordBySubId(
        id,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("subscribe.delete_subs_success"))),
          );
        },
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("subscribe.delete_subs_failed"))),
          );
        },
      );

      setState(() {
        subscribe.removeWhere((item) => item.subId == id);
        _deleteModeIds.remove(id);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("subscribe.delete_failed"))));
    }
  }

  void _toggleDeleteMode(int id) {
    setState(() {
      if (_deleteModeIds.contains(id)) {
        _deleteModeIds.remove(id);
      } else {
        _deleteModeIds.add(id);
      }
    });
  }

  void initTabBarListener() {
    _tabController.addListener(() {
      _deleteModeIds.clear();
    });
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
          if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) ...[
            IconButton(
              tooltip: 'Refresh All',
              onPressed: () {
                _fetchPlaybackHistoryFromServer();
                _fetchSubscribeHistoryFromServer();
              },
              icon: Icon(Icons.refresh_rounded),
            ),
          ],
          if (_deleteModeIds.isNotEmpty)
            IconButton(
              icon: Icon(Icons.remove_done_rounded),
              onPressed: () {
                setState(() {
                  _deleteModeIds.clear();
                });
              },
            ),
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
                Tab(text: tr("subscribe.tab_subs")),
                Tab(text: tr("subscribe.tab_view")),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  //订阅部分
                  subscribe.isEmpty
                      ? LoadingOrShowMsg(
                          msg: tr("subscribe.refresh_btn_subs"),
                          onMsgTab: () async {
                            await _fetchSubscribeHistoryFromServer();
                          },
                        )
                      : RefreshIndicator(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: subscribe.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLandscape ? 6 : 3,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                  childAspectRatio: 0.6,
                                ),
                            itemBuilder: (context, index) {
                              final item = subscribe[index];
                              return MediaGrid(
                                showRating: false,
                                id: "subscribe_${item.subId}",
                                imageUrl: item.imgUrl,
                                title: item.title,
                                showDeleteIcon: _deleteModeIds.contains(
                                  item.subId,
                                ),
                                onLongPress: (_) =>
                                    _toggleDeleteMode(item.subId),
                                onDelete: _deleteSubscribeHistory,
                                onTap: () {
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
                                },
                              );
                            },
                          ),
                          onRefresh: () async {
                            await _fetchSubscribeHistoryFromServer();
                          },
                        ),
                  //播放历史部分
                  playback.isEmpty
                      ? LoadingOrShowMsg(
                          msg: tr("subscribe.refresh_btn_view"),
                          onMsgTab: () async {
                            await _fetchPlaybackHistoryFromServer();
                          },
                        )
                      : RefreshIndicator(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemCount: playback.length,
                            itemBuilder: (context, index) {
                              final item = playback[index];
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
                                nameCn: item.title,
                                showDeleteIcon: _deleteModeIds.contains(
                                  item.subId,
                                ),
                                onLongPress: (_) =>
                                    _toggleDeleteMode(item.subId),
                                onDelete: _deletePlaybackHistory,
                                onTap: () {
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
                                },
                              );
                            },
                          ),
                          onRefresh: () async {
                            await _fetchPlaybackHistoryFromServer();
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
