import 'dart:async';
import 'dart:developer' show log;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/entity/danmu_item.dart';
import 'package:holo/entity/episode.dart';
import 'package:holo/entity/logvar_episode.dart';
import 'package:holo/entity/media.dart';

import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/component/meida_card.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/cap_video_player.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';

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
  List<LogvarEpisode>? _danmakuList;
  LogvarEpisode? _bestMatch;
  Danmu? _dammaku;
  bool _isDanmakuLoading = false;
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

  void _fetchViewInfo({
    int position = 0,
    Function(String e)? onComplete,
  }) async {
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
        _loadDanmaku(
          isFirstLoad: true,
          onComplete: (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e)));
          },
        );
        final newUrl = await source.fetchView(
          _detail!.lines![lineIndex].episodes![episodeIndex],
          (e) => setState(() {
            log("fetchView error: $e");
            msg = "player.playback_error".tr();
            onComplete?.call(msg);
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
        onComplete?.call(msg);
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

  void _loadDanmaku({
    bool isFirstLoad = true,
    Function(String e)? onComplete,
  }) async {
    if (_isDanmakuLoading) {
      return;
    }
    setState(() {
      _isDanmakuLoading = true;
    });
    if (isFirstLoad) {
      var data = await Api.logvar.fetchEpisodeFromLogvar(
        subject?.nameCn ?? "",
        (e) {
          if (mounted) {
            setState(() {
              _isDanmakuLoading = false;
              onComplete?.call(e.toString());
            });
          }
        },
      );
      setState(() {
        _danmakuList = data;
      });
      double score = 0;

      for (var element in data) {
        var temp = JaroWinklerSimilarity.apply(
          element.animeTitle,
          subject?.nameCn ?? "",
        );
        if (temp > score) {
          score = temp;
          setState(() {
            _bestMatch = element;
          });
        }
      }
      if (_bestMatch == null) {
        setState(() {
          onComplete?.call("player.danmaku_not_exist".tr());
        });
        return;
      }
    }

    final danmu = await Api.logvar.fetchDammakuSync(
      _bestMatch!.episodes![episodeIndex].episodeId!,
      (e) {
        if (mounted) {
          setState(() {
            _isDanmakuLoading = false;
            onComplete?.call("player.danmaku_load_error".tr());
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _isDanmakuLoading = false;
        _dammaku = danmu;
        onComplete?.call("player.danmaku_loaded".tr());
      });
    }
  }

  void _onDanmakuSourceChange(LogvarEpisode e) {
    if (e.animeId == _bestMatch?.animeId) {
      return;
    }
    setState(() {
      _bestMatch = e;
    });
    _loadDanmaku(isFirstLoad: false);
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

  Widget _buildDetailSkeleton() {
    return Column(
      spacing: 10,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity * 0.6,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity * 0.4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity * 0.3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerSkeleton() {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[500]!,
        highlightColor: Colors.grey[300]!,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Shimmer.fromColors(
            baseColor: Colors.grey[500]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800]!,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          subtitle: Shimmer.fromColors(
            baseColor: Colors.grey[500]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              height: 14,
              width: double.infinity * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[800]!,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
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
                            dammaku: _dammaku,
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
                              dammaku: _dammaku,
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
                                  Tab(text: "player.summary".tr()),
                                  Tab(text: "player.episodes".tr()),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  barrierLabel: "fff",
                                  builder: (context) {
                                    return Column(
                                      spacing: 8,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            'player.choose_danmaku_sheet_text'
                                                .tr(),
                                          ),
                                        ),
                                        if (_danmakuList == null ||
                                            _danmakuList!.isEmpty)
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                'player.no_danmaku_sheet_text'
                                                    .tr(),
                                              ),
                                            ),
                                          ),
                                        ...List.generate(
                                          _danmakuList?.length ?? 0,
                                          (index) => Column(
                                            children: [
                                              ListTile(
                                                selected:
                                                    _bestMatch?.animeId ==
                                                    _danmakuList?[index]
                                                        .animeId,
                                                title: Text(
                                                  _danmakuList?[index]
                                                          .animeTitle ??
                                                      '',
                                                ),
                                                subtitle: Text(
                                                  _danmakuList?[index]
                                                          .animeTitle ??
                                                      '',
                                                ),
                                                onTap: () {
                                                  _onDanmakuSourceChange(
                                                    _danmakuList![index],
                                                  );
                                                },
                                              ),
                                              Divider(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                "player.danmaku_selection".tr(),
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            // 路线选择
                            PopupMenuButton(
                              child: TextButton.icon(
                                onPressed: null,
                                label: Text(
                                  'player.route_selection'.tr(),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              itemBuilder: (context) => [
                                ...List.generate(
                                  _detail?.lines?.length ?? 1,
                                  (index) => PopupMenuItem(
                                    value: index,
                                    child: Text(
                                      '${'player.route_number'.tr(args: [(index + 1).toString()])}${index == lineIndex ? '•' : ''}',
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
                          ],
                        ),

                        Flexible(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  child: subject == null
                                      ? _buildDetailSkeleton()
                                      : Column(
                                          spacing: 6,
                                          children: [
                                            MeidaCard(
                                              id: subject!.id!,
                                              imageUrl: subject!.images?.large!,

                                              nameCn:
                                                  subject!.nameCn ??
                                                  subject!.name ??
                                                  '',
                                              genre: subject!.metaTags?.join(
                                                '/',
                                              ),
                                              episode: subject!.eps ?? 0,
                                              rating: subject!.rating?.score,
                                              height: 180,
                                              airDate: subject!.infobox
                                                  ?.firstWhere(
                                                    (element) =>
                                                        element.key?.contains(
                                                          "detail.air_date_key"
                                                              .tr(),
                                                        ) ??
                                                        false,
                                                    orElse: () => InfoBox(),
                                                  )
                                                  .value,
                                            ),
                                            Container(
                                              width: double.infinity,

                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,

                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                context.tr(
                                                  'player.danmaku_statistics',
                                                  args: [
                                                    (_danmakuList?.length ?? 0)
                                                        .toString(),
                                                    (_dammaku
                                                                ?.comments
                                                                ?.length ??
                                                            0)
                                                        .toString(),
                                                    (_dammaku
                                                                ?.comments
                                                                ?.length ??
                                                            0)
                                                        .toString(),
                                                  ],
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            ),
                                            ListTile(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              tileColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              title: Text(
                                                "player.datasource".tr(),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                              subtitle: Text(
                                                source.getName(),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                              leading: Image.network(
                                                width: 50,
                                                source.getLogoUrl(),
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Icon(Icons.error);
                                                    },
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              // 剧集列表
                              msg.isNotEmpty
                                  ? LoadingOrShowMsg(msg: msg)
                                  : _episode == null
                                  ? _buildShimmerSkeleton()
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
                                        itemBuilder: (context, index) => ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                "player.no_episode_name".tr(),
                                          ),
                                          title: Text(
                                            '${index + 1}${episodeIndex == index ? "•" : ""}',
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
