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
import 'package:holo/ui/component/media_card.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/cap_video_player.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';

import 'package:shimmer/shimmer.dart';

import 'package:video_player/video_player.dart';

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
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  late Data subject = widget.subject;
  bool _isFullScreen = false;
  String msg = "";

  int episodeIndex = 0;
  int lineIndex = 0;
  Episode? _episode;
  Detail? _detail;
  bool isloading = false;
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
            ).showSnackBar(SnackBar(content: Text(e), showCloseIcon: true));
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
    if (index == lineIndex) {
      return;
    }
    setState(() {
      lineIndex = index;
    });
    _fetchViewInfo();
  }

  void _onEpisodeSelected(int index) {
    if (index >= _detail!.lines![lineIndex].episodes!.length) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("player.episode_not_exist".tr())),
        );
      });
      return;
    }
    if (index == episodeIndex) {
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
    final res = await Api.bangumi.fethcEpisodeSync(
      widget.subject.id!,
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

  void _toggleFullScreen(bool isFullScreen) async {
    setState(() {
      _isFullScreen = isFullScreen;
    });
    if (isFullScreen) {
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
      // _danmuMsg = "player.danmaku_loading".tr();
    });
    if (isFirstLoad) {
      var data = await Api.logvar.fetchEpisodeFromLogvar(subject.nameCn ?? "", (
        e,
      ) {
        if (mounted) {
          setState(() {
            _isDanmakuLoading = false;
            onComplete?.call(e.toString());
          });
        }
      });
      setState(() {
        _danmakuList = data;
      });
      double score = 0;

      for (var element in data) {
        var temp = JaroWinklerSimilarity.apply(
          element.animeTitle,
          subject.nameCn ?? "",
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

  Widget _buildFadeSummarySection() {
    return Column(
      spacing: 10,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 30,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity * 0.4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity * 0.3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white38,
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

  Widget _buildFadeEpisodeSection() {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          subtitle: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 14,
              width: double.infinity * 0.8,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _isFullScreen ? Colors.black : null,
      body: SafeArea(
        child: Center(
          child: PopScope(
            canPop: !_isFullScreen,
            onPopInvokedWithResult: (didPop, result) {
              setState(() {
                _toggleFullScreen(false);
              });
            },
            child: Column(
              children: [
                //视频播放器
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Container(
                    color: Colors.black,
                    height: double.infinity,
                    width: double.infinity,
                    child: Center(
                      child: _controller != null && !isloading
                          ? CapVideoPlayer(
                              title: widget.nameCn,
                              isloading: isloading,
                              controller: _controller!,
                              isFullScreen: _isFullScreen,
                              currentEpisodeIndex: episodeIndex,
                              dammaku: _dammaku,
                              episodeList:
                                  _episode?.data
                                      ?.map((e) => e.name!)
                                      .toList() ??
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
                                  _toggleFullScreen(isFullScreen);
                                });
                              },
                              onBackPressed: () {
                                if (_isFullScreen) {
                                  setState(() {
                                    _toggleFullScreen(false);
                                  });
                                } else {
                                  context.pop();
                                }
                              },
                            )
                          : LoadingOrShowMsg(
                              msg: msg,
                              backgroundColor: Colors.black,
                            ),
                    ),
                  ),
                ),
                //剧集列表
                if (!_isFullScreen)
                  Flexible(
                    flex: 2,
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
                            IconButton(
                              tooltip: "player.danmaku_selection".tr(),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  barrierLabel: "fff",
                                  builder: (context) {
                                    return Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          child: Center(
                                            child: Text(
                                              'player.choose_danmaku_sheet_text'
                                                  .tr(),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: StatefulBuilder(
                                            builder: (context, setState) =>
                                                (_danmakuList == null ||
                                                    _danmakuList!.isEmpty)
                                                ? Center(
                                                    child: Text(
                                                      'player.no_danmaku_sheet_text'
                                                          .tr(),
                                                    ),
                                                  )
                                                : ListView.separated(
                                                    itemCount:
                                                        _danmakuList?.length ??
                                                        0,
                                                    separatorBuilder:
                                                        (context, index) =>
                                                            Divider(height: 1),
                                                    itemBuilder: (context, index) {
                                                      return ListTile(
                                                        selected:
                                                            _bestMatch
                                                                ?.animeId ==
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
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: Icon(
                                Icons.subtitles_rounded,
                                color: Colors.grey,
                              ),
                            ),
                            // 路线选择
                            PopupMenuButton(
                              tooltip: 'player.route_selection'.tr(),
                              borderRadius: BorderRadius.circular(50),
                              child: IconButton(
                                onPressed: null,
                                icon: Icon(Icons.source_rounded),
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
                              //简介
                              Container(
                                padding: EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  child: Column(
                                    spacing: 6,
                                    children: [
                                      MediaCard(
                                        id: "player_${subject.id!}",
                                        imageUrl: subject.images?.large!,
                                        nameCn:
                                            subject.nameCn ??
                                            subject.name ??
                                            '',
                                        genre: subject.metaTags?.join('/'),
                                        episode: subject.eps ?? 0,
                                        rating: subject.rating?.score,
                                        height: 180,
                                        airDate: subject.infobox
                                            ?.firstWhere(
                                              (element) =>
                                                  element.key?.contains(
                                                    "detail.air_date_key".tr(),
                                                  ) ??
                                                  false,
                                              orElse: () => InfoBox(),
                                            )
                                            .value,
                                      ),
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: _dammaku != null ? 38 : 0,
                                        width: double.infinity,
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: _isDanmakuLoading
                                              ? LinearProgressIndicator()
                                              : Text(
                                                  context.tr(
                                                    'player.danmaku_statistics',
                                                    args: [
                                                      (_danmakuList?.length ??
                                                              0)
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
                                      ),
                                      ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        tileColor: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
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
                                              (context, error, stackTrace) {
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
                                  ? _buildFadeEpisodeSection()
                                  : GridView.builder(
                                      key: PageStorageKey("player_episodes"),
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
                                        title: Row(
                                          children: [
                                            Text('${index + 1}'),
                                            SizedBox(width: 10),
                                            if (episodeIndex == index)
                                              ColorFiltered(
                                                colorFilter: ColorFilter.mode(
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  BlendMode.srcATop,
                                                ),
                                                child: LottieBuilder.asset(
                                                  "lib/assert/lottie/playing.json",
                                                  repeat: true,
                                                  width: 40,
                                                ),
                                              ),
                                          ],
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
      ),
    );
  }
}
