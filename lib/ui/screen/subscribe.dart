import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/api/subscribe_api.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subscribe_history.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/ui/component/media_grid.dart';
import 'package:holo/ui/component/meida_card.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("获取云端播放记录失败")));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("获取云端订阅记录失败")));
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

  void _deletePlaybackHistory(int id) {
    try {
      LocalStore.removePlaybackHistoryBySubId(id);
      PlayBackApi.deletePlaybackRecordBySubId(
        id,
        () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("删除云端播放记录成功")));
        },
        (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("删除云端播放记录失败: $error")));
        },
      );

      setState(() {
        playback.removeWhere((item) => item.subId == id);
        _deleteModeIds.remove(id);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("删除失败: $e")));
    }
  }

  void _deleteSubscribeHistory(int id) {
    try {
      LocalStore.removeSubscribeHistoryBySubId(id);
      SubscribeApi.deleteSubscribeRecordBySubId(
        id,
        () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("删除云端订阅记录成功")));
        },
        (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("删除云端订阅记录失败: $error")));
        },
      );

      setState(() {
        subscribe.removeWhere((item) => item.subId == id);
        _deleteModeIds.remove(id);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("删除失败: $e")));
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
    return Scaffold(
      appBar: AppBar(title: const Text('订阅')),

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
              controller: _tabController,
              tabs: const [
                Tab(text: '订阅'),
                Tab(text: '历史记录'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  subscribe.isEmpty
                      ? LoadingOrShowMsg(
                          msg: '暂无订阅,点我刷新试试',
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
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                  childAspectRatio: 0.6,
                                ),
                            itemBuilder: (context, index) {
                              final item = subscribe[index];
                              return MediaGrid(
                                showRating: false,
                                id: item.subId,
                                imageUrl: item.imgUrl,
                                title: item.title,
                                showDeleteIcon: _deleteModeIds.contains(
                                  item.subId,
                                ),
                                onLongPress: (_) =>
                                    _toggleDeleteMode(item.subId),
                                onDelete: _deleteSubscribeHistory,
                                onTap: () => context.push(
                                  '/detail',
                                  extra: {
                                    "id": item.subId,
                                    "keyword": item.title,
                                  },
                                ),
                              );
                            },
                          ),
                          onRefresh: () async {
                            await _fetchSubscribeHistoryFromServer();
                          },
                        ),
                  playback.isEmpty
                      ? LoadingOrShowMsg(
                          msg: '暂无历史记录,点我刷新试试',
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
                              return MeidaCard(
                                height: 190,
                                lastViewAt: item.lastPlaybackAt,
                                historyEpisode: item.episodeIndex,
                                id: item.subId,
                                imageUrl: item.imgUrl,
                                nameCn: item.title,
                                showDeleteIcon: _deleteModeIds.contains(
                                  item.subId,
                                ),
                                onLongPress: (_) =>
                                    _toggleDeleteMode(item.subId),
                                onDelete: _deletePlaybackHistory,
                                onTap: () => context.push(
                                  '/detail',
                                  extra: {
                                    "id": item.subId,
                                    "keyword": item.title,
                                  },
                                ),
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
