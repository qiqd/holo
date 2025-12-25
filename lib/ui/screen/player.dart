import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_holo/entity/episode.dart';
import 'package:mobile_holo/entity/history.dart';
import 'package:mobile_holo/entity/media.dart';
import 'package:mobile_holo/entity/subject.dart';
import 'package:mobile_holo/service/api.dart';
import 'package:mobile_holo/service/source_service.dart';
import 'package:mobile_holo/service/util/jaro_winkler_similarity.dart';
import 'package:mobile_holo/service/util/local_store.dart';
import 'package:mobile_holo/ui/component/cap_video_player.dart';
import 'package:mobile_holo/ui/component/loading_msg.dart';

import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final String mediaId;
  final Data subject;
  final SourceService source;
  final String nameCn;
  const PlayerScreen({
    super.key,
    required this.mediaId,
    required this.subject,
    required this.source,
    required this.nameCn,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isFullScreen = false;
  String msg = "";
  int episodeIndex = 0;
  int lineIndex = 0;
  Episode? _episode;
  Detail? _detail;
  bool isloading = false;
  Data? subject;
  int historyPosition = 0;
  late final String nameCn = widget.nameCn;
  late final String mediaId = widget.mediaId;
  late final SourceService source = widget.source;
  VideoPlayerController? _controller;

  late final TabController _tabController = TabController(
    vsync: this,
    length: 2,
  );

  Future<void> _fetchMediaEpisode() async {
    isloading = true;
    try {
      final res = await source.fetchDetail(
        mediaId,
        (e) => setState(() {
          log("fetchDetail1 error: $e");
          msg = e.toString();
        }),
      );

      if (mounted) {
        setState(() {
          _detail = res;
        });
      }
    } catch (e) {
      log("fetchDetail2 error: $e");
      setState(() {
        msg = e.toString();
      });
    } finally {
      isloading = false;
    }
  }

  void _fetchViewInfo({int position = 0}) async {
    msg = "";
    isloading = true;
    try {
      if (_detail != null) {
        await _controller?.pause();
        await _controller?.dispose();
        _controller = null;
        final newUrl = await source.fetchView(
          _detail!.lines![lineIndex].episodes![episodeIndex],
          (e) => setState(() {
            log("fetchView error: $e");
            msg = "无法获取播放地址,换条路线试试";
          }),
        );

        final newController = VideoPlayerController.networkUrl(
          Uri.parse(newUrl ?? ""),
        );
        await newController.initialize();
        if (mounted) {
          setState(() {
            _controller = newController;
            _controller?.seekTo(Duration(seconds: position));
            _controller?.play();
          });
        }
      }
    } catch (e) {
      log("fetchView error: $e");
      setState(() {
        msg = e.toString();
      });
    } finally {
      isloading = false;
    }
  }

  void _onLineSelected(int index) {
    setState(() {
      lineIndex = index;
    });
    _fetchViewInfo();
  }

  void _onEpisodeSelected(int index) {
    if (index >= _detail!.lines![lineIndex].episodes!.length) {
      setState(() {
        msg = "该剧集不存在";
      });
      return;
    }
    setState(() {
      episodeIndex = index;
    });
    _fetchViewInfo();
  }

  void _loadHistory() async {
    final history = LocalStore.getHistoryById(widget.subject.id!);
    if (history != null) {
      setState(() {
        episodeIndex = history.episodeIndex;
        lineIndex = history.lineIndex;
        historyPosition = history.position;
      });
    }
  }

  void _fetchEpisode() async {
    final newSubject = await Api.bangumi.fetchSearchSync(nameCn, (e) {
      log("fetchSearchSync error: $e");
      setState(() {
        msg = e.toString();
      });
    });
    var data = newSubject!.data ?? [];
    data = data.where((s) => s.nameCn != null).toList();
    final name2IdMap = {for (final item in data) item.nameCn!: item.id!};
    final rs = {
      for (final item in name2IdMap.entries)
        JaroWinklerSimilarity.apply(nameCn, item.key): item.value,
    };
    final maxScore = rs.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    final subjectId = rs[maxScore];
    subject = newSubject.data?.firstWhere((s) => s.id == subjectId);
    final res = await Api.bangumi.fethcEpisodeSync(
      subjectId!,
      (e) => setState(() {
        log("fetchEpisode error: $e");
        msg = e.toString();
      }),
    );
    if (mounted) {
      setState(() {
        _episode = res;
      });
    }
  }

  void _storeLocalHistory() {
    History history = History(
      id: widget.subject.id!,
      title: nameCn,
      episodeIndex: episodeIndex,
      lineIndex: lineIndex,
      lastViewAt: DateTime.now(),
      position: _controller?.value.position.inSeconds ?? 0,
      imgUrl: widget.subject.images?.large ?? "",
      isLove: false,
    );
    LocalStore.addHistory(history);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      log("pause");
      _storeLocalHistory();
    } else if (state == AppLifecycleState.resumed) {
      log("resume");
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    _fetchEpisode();
    _fetchMediaEpisode().then(
      (value) => _fetchViewInfo(position: historyPosition),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _storeLocalHistory();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        backgroundColor: _isFullScreen ? Colors.black : null,
        body: SafeArea(
          child: _isFullScreen
              ? Center(
                  child: AspectRatio(
                    aspectRatio: _controller == null
                        ? 16 / 9
                        : _controller!.value.aspectRatio,
                    child: _controller != null && !isloading
                        ? CapVideoPlayer(
                            title: widget.nameCn,
                            isloading: isloading,
                            controller: _controller!,
                            isFullScreen: _isFullScreen,
                            onError: (error) => setState(() {
                              msg = error.toString();
                            }),
                            onNextTab: () {
                              if (isloading ||
                                  episodeIndex + 1 >
                                      _detail!
                                              .lines![lineIndex]
                                              .episodes!
                                              .length -
                                          1) {
                                return;
                              }
                              setState(() {
                                ++episodeIndex;
                              });
                              _fetchViewInfo();
                            },
                            onFullScreenChanged: (isFullScreen) {
                              setState(() {
                                _isFullScreen = isFullScreen;
                              });
                            },
                          )
                        : LoadingOrShowMsg(
                            msg: msg,
                            backgroundColor: Colors.black,
                          ),
                  ),
                )
              : Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _controller != null && !isloading
                          ? CapVideoPlayer(
                              title: widget.nameCn,
                              isloading: isloading,
                              controller: _controller!,
                              isFullScreen: _isFullScreen,
                              onError: (error) => setState(() {
                                msg = error.toString();
                              }),
                              onNextTab: () {
                                if (isloading ||
                                    episodeIndex + 1 >
                                        _detail!
                                                .lines![lineIndex]
                                                .episodes!
                                                .length -
                                            1) {
                                  return;
                                }
                                setState(() {
                                  ++episodeIndex;
                                });
                                _fetchViewInfo();
                              },
                              onFullScreenChanged: (isFullScreen) {
                                setState(() {
                                  _isFullScreen = isFullScreen;
                                });
                              },
                            )
                          : LoadingOrShowMsg(
                              msg: msg,
                              backgroundColor: Colors.black,
                            ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TabBar(
                                  dividerColor: Colors.transparent,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  padding: EdgeInsets.all(0),
                                  controller: _tabController,
                                  tabs: [
                                    Tab(text: "评论"),
                                    Tab(text: "选集"),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: PopupMenuButton(
                                  child: TextButton.icon(
                                    onPressed: null,
                                    label: Text('路线选择'),
                                  ),
                                  itemBuilder: (context) => [
                                    ...List.generate(
                                      _detail?.lines?.length ?? 1,
                                      (index) => PopupMenuItem(
                                        value: index,
                                        child: Text('路线${index + 1}'),
                                        onTap: () {
                                          if (index == lineIndex || isloading) {
                                            return;
                                          }
                                          _onLineSelected(index);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                Container(child: Center(child: Text("暂无评论"))),
                                _episode == null
                                    ? LoadingOrShowMsg(msg: msg)
                                    : GridView.builder(
                                        padding: EdgeInsets.all(10),
                                        itemCount: _episode?.data?.length ?? 0,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 5,
                                              crossAxisSpacing: 5,
                                            ),
                                        itemBuilder: (context, index) =>
                                            ListTile(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              selected: episodeIndex == index,
                                              onTap: () {
                                                if (episodeIndex == index ||
                                                    isloading) {
                                                  return;
                                                }
                                                _onEpisodeSelected(index);
                                              },
                                              subtitle: Text(
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                                _episode?.data?[index].nameCn ??
                                                    "暂无剧集名称",
                                              ),
                                              title: Text(
                                                (index + 1).toString(),
                                              ),
                                            ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
