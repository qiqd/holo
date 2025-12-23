import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_mikufans/entity/episode.dart';
import 'package:mobile_mikufans/entity/media.dart';
import 'package:mobile_mikufans/entity/subject.dart';
import 'package:mobile_mikufans/service/api.dart';
import 'package:mobile_mikufans/service/source_service.dart';
import 'package:mobile_mikufans/service/util/jaro_winkler_similarity.dart';
import 'package:mobile_mikufans/ui/component/cap_video_player.dart';
import 'package:mobile_mikufans/ui/component/loading_msg.dart';

import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final String mediaId;
  final int subjectId;
  final SourceService source;
  final String nameCn;
  const PlayerScreen({
    super.key,
    required this.mediaId,
    required this.subjectId,
    required this.source,
    required this.nameCn,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _isFullScreen = false;
  String msg = "";
  int episodeIndex = 0;
  int lineIndex = 0;
  Episode? _episode;
  Detail? _detail;
  bool isloading = false;
  Data? subject;
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

      setState(() {
        _detail = res;
      });
    } catch (e) {
      log("fetchDetail2 error: $e");
      setState(() {
        msg = e.toString();
      });
    } finally {
      isloading = false;
    }
  }

  void _fetchViewInfo() async {
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
        setState(() {
          _controller = newController;
          _controller?.play();
        });
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
    setState(() {
      episodeIndex = index;
    });
    _fetchViewInfo();
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
    setState(() {
      _episode = res;
    });
  }

  @override
  void initState() {
    _fetchEpisode();
    _fetchMediaEpisode().then((value) => _fetchViewInfo());
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
                                  child: Text('路线选择'),
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
                                Container(),
                                Container(
                                  child: ListView.builder(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    itemCount: _episode?.data?.length ?? 0,
                                    itemBuilder: (itemBuilder, index) {
                                      return Column(
                                        children: [
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
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              _episode?.data?[index].nameCn ??
                                                  "暂无剧集名称",
                                            ),
                                            title: Text((index + 1).toString()),
                                          ),
                                          Divider(height: 6),
                                        ],
                                      );
                                    },
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
