import 'dart:async';
import 'dart:developer' show log;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/entity/episode.dart';
import 'package:holo/entity/media.dart';

import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/cap_video_player.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PlayerScreen extends StatefulWidget {
  final String mediaId;
  final Data subject;
  final SourceService source;
  final String nameCn;
  final bool isLove;
  const PlayerScreen({
    super.key,
    required this.mediaId,
    required this.subject,
    required this.source,
    required this.nameCn,
    this.isLove = false,
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
  String? playUrl;
  bool _isActive = true;

  late final String nameCn = widget.nameCn;
  late final String mediaId = widget.mediaId;
  late final SourceService source = widget.source;
  VideoPlayerController? _controller;
  late final TabController _tabController = TabController(
    vsync: this,
    length: 2,
  );
  final ScrollController episodeListScrollController = ScrollController();
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
        lineIndex = lineIndex.clamp(0, _detail!.lines!.length - 1);
        episodeIndex = episodeIndex.clamp(
          0,
          _detail!.lines![lineIndex].episodes!.length - 1,
        );
        final newUrl = await source.fetchView(
          _detail!.lines![lineIndex].episodes![episodeIndex],
          (e) => setState(() {
            log("fetchView error: $e");
            msg = "player.playback_error".tr();
          }),
        );
        playUrl = newUrl;
        final newController = VideoPlayerController.networkUrl(
          Uri.parse(newUrl ?? ""),
        );
        await newController.initialize();
        if (mounted) {
          setState(() {
            _controller = newController;
            _controller?.seekTo(Duration(seconds: position));
            _isActive ? _controller?.play() : _controller?.pause();
          });
        }
      }
    } catch (e) {
      log("fetchView error: $e");
      setState(() {
        msg = "player.playback_error".tr();
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
        msg = "player.episode_not_exist".tr();
      });
      return;
    }
    setState(() {
      episodeIndex = index;
    });
    _fetchViewInfo();
  }

  void _loadHistory() async {
    final history = LocalStore.getPlaybackHistoryById(widget.subject.id!);
    if (history != null && mounted) {
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
    if (playUrl == null) {
      return;
    }
    PlaybackHistory history = PlaybackHistory(
      subId: widget.subject.id!,
      title: nameCn,
      episodeIndex: episodeIndex,
      lineIndex: lineIndex,
      lastPlaybackAt: DateTime.now(),
      createdAt: DateTime.now(),
      position: _controller?.value.position.inSeconds ?? 0,
      imgUrl: widget.subject.images?.large ?? "",
    );
    _syncPlaybackHistory(history);
    LocalStore.addPlaybackHistory(history);
  }

  void _toggleFullScreen() async {
    if (_isFullScreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _syncPlaybackHistory(PlaybackHistory history) {
    PlayBackApi.savePlaybackHistory(
      history,
      () {
        history.isSync = true;
      },
      (e) {
        log("savePlaybackHistory error: $e");
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        _isActive = false;
      });
      _storeLocalHistory();
    }
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isActive = true;
      });
    }
    if (state == AppLifecycleState.inactive) {
      _storeLocalHistory();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangeDependencies() {
    _storeLocalHistory();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _loadHistory();
    _fetchEpisode();
    WidgetsBinding.instance.addObserver(this);
    _fetchMediaEpisode().then(
      (value) => _fetchViewInfo(position: historyPosition),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _storeLocalHistory();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    log("didRequestAppExit");
    _storeLocalHistory();
    return super.didRequestAppExit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isFullScreen ? Colors.black : null,
      body: SafeArea(
        child: _isFullScreen
            ? Center(
                child: PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) {
                    setState(() {
                      _isFullScreen = false;
                      _toggleFullScreen();
                    });
                  },
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
                            currentEpisodeIndex: episodeIndex,
                            episodeList:
                                _episode?.data?.map((e) => e.name!).toList() ??
                                [],
                            onError: (error) => setState(() {
                              msg = error.toString();
                            }),
                            onEpisodeSelected: (index) =>
                                _onEpisodeSelected(index),
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
                                _toggleFullScreen();
                              });
                            },
                            onBackPressed: () {
                              setState(() {
                                _isFullScreen = false;
                                _toggleFullScreen();
                              });
                            },
                          )
                        : LoadingOrShowMsg(
                            msg: msg,
                            backgroundColor: Colors.black,
                          ),
                  ),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: AspectRatio(
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
                                  _toggleFullScreen();
                                });
                              },
                              onBackPressed: () {
                                context.pop();
                              },
                            )
                          : LoadingOrShowMsg(
                              msg: msg,
                              backgroundColor: Colors.black,
                            ),
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
                                  Tab(text: "player.comments".tr()),
                                  Tab(text: "player.episodes".tr()),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: PopupMenuButton(
                                child: TextButton.icon(
                                  onPressed: null,
                                  label: Text('player.route_selection'.tr()),
                                ),
                                itemBuilder: (context) => [
                                  ...List.generate(
                                    _detail?.lines?.length ?? 1,
                                    (index) => PopupMenuItem(
                                      value: index,
                                      child: Text(
                                        'player.route_number'.tr(
                                          args: [(index + 1).toString()],
                                        ),
                                      ),
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

                        Flexible(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              SizedBox(
                                child: Center(
                                  child: Text("player.no_comments".tr()),
                                ),
                              ),
                              _episode == null
                                  ? LoadingOrShowMsg(msg: msg)
                                  : VisibilityDetector(
                                      key: Key("player_episodes"),
                                      child: GridView.builder(
                                        controller: episodeListScrollController,
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
                                                    "player.no_episode_name"
                                                        .tr(),
                                              ),
                                              title: Text(
                                                (index + 1).toString(),
                                              ),
                                            ),
                                      ),
                                      onVisibilityChanged: (info) {
                                        if (info.visibleFraction > 0) {
                                          episodeListScrollController.animateTo(
                                            episodeIndex * 1.0,
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
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
    );
  }
}
