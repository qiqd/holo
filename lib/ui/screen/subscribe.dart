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
        playback.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    playback.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    subscribe.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
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
                              return MediaGrid(
                                showRating: false,
                                id: subscribe[index].subId,
                                imageUrl: subscribe[index].imgUrl,
                                title: subscribe[index].title,
                                onTap: () => context.push(
                                  '/detail',
                                  extra: {
                                    "id": subscribe[index].subId,
                                    "keyword": subscribe[index].title,
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
                              return MeidaCard(
                                height: 190,
                                lastViewAt: playback[index].createdAt,
                                historyEpisode: playback[index].episodeIndex,
                                id: playback[index].subId,
                                imageUrl: playback[index].imgUrl,
                                nameCn: playback[index].title,
                                onTap: () => context.push(
                                  '/detail',
                                  extra: {
                                    "id": playback[index].subId,
                                    "keyword": playback[index].title,
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
