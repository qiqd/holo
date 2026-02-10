import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/entity/episode.dart';
import 'package:holo/entity/logvar_episode.dart';
import 'package:holo/entity/media.dart' as holo_media;
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subject.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/component/cap_video_player_kit.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/local_store.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:logger/logger.dart';
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
  final _globalKey = GlobalKey<ScaffoldState>();
  final Logger _logger = Logger();
  late Data subject = widget.subject;
  bool _isFullScreen = false;
  String msg = "";
  int episodeIndex = 0;
  int lineIndex = 0;
  Episode? _episode;
  holo_media.Detail? _detail;
  bool isloading = false;
  int historyPosition = 0;
  String? playUrl;
  bool _isActive = true;
  List<LogvarEpisode>? _danmakuList;
  LogvarEpisode? _bestMatch;
  Danmu? _dammaku;
  bool _isDanmakuLoading = false;
  bool _showInfo = true;
  bool _isTablet = false;
  bool _isInputting = false;
  final String _danmakuKeyword = '';
  late final String nameCn = widget.nameCn;
  late final String mediaId = widget.mediaId;
  late final SourceService source = widget.source;
  final _playerNotifier = ValueNotifier<VideoPlayerController?>(null);
  Duration _position = .zero;
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

  Future<void> _fetchViewInfo({
    int position = 0,
    bool loadDanmaku = true,
    Function(String e)? onComplete,
  }) async {
    safeSetState(() {
      msg = "";
      isloading = true;
    });
    try {
      if (_detail != null) {
        lineIndex = lineIndex.clamp(0, _detail!.lines!.length - 1);
        episodeIndex = episodeIndex.clamp(
          0,
          _detail!.lines![lineIndex].episodes!.length - 1,
        );
        if (loadDanmaku) {
          _loadDanmaku(
            isFirstLoad: true,
            keyword: _danmakuKeyword.isNotEmpty ? _danmakuKeyword : nameCn,
            onComplete: (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e), showCloseIcon: true));
            },
          );
        }
        _playerNotifier.value?.dispose();
        _playerNotifier.value = null;
        final newUrl = await source.fetchPlaybackUrl(
          _detail!.lines![lineIndex].episodes![episodeIndex],
          (e) => setState(() {
            _logger.e("fetchView error: $e");
            msg = "player.playback_error".tr();
            isloading = false;
            onComplete?.call(msg);
          }),
        );
        playUrl = newUrl;
        _logger.i('new url: $newUrl');
        _logger.i('seek to: $position');
        final newController = VideoPlayerController.networkUrl(
          Uri.parse(newUrl ?? ""),
        );
        await newController.initialize();
        safeSetState(() {
          msg = '';
          _playerNotifier.value = newController;
        });
        _playerNotifier.value?.seekTo(Duration(seconds: position));
        _isActive
            ? _playerNotifier.value?.play()
            : _playerNotifier.value?.pause();
      }
    } catch (e) {
      _logger.e("fetchView error: $e");
      if (mounted) {
        setState(() {
          msg = "player.playback_error".tr();
          onComplete?.call(msg);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isloading = false;
        });
      }
    }
  }

  void _onLineSelected(int index) {
    if (index == lineIndex) {
      return;
    }
    setState(() {
      lineIndex = index;
    });
    _fetchViewInfo(position: _position.inSeconds, loadDanmaku: false);
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
    final res = await Api.bangumi.fethcEpisode(
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

  void _storeLocalHistory() async {
    if (playUrl == null) {
      return;
    }
    final p =
        (await _playerNotifier.value?.position ?? Duration.zero).inSeconds;
    if (p <= 0) {
      return;
    }
    PlaybackHistory history = PlaybackHistory(
      subId: widget.subject.id!,
      title: nameCn,
      episodeIndex: episodeIndex,
      lineIndex: lineIndex,
      lastPlaybackAt: DateTime.now(),
      createdAt: DateTime.now(),
      // position: _controller?.value.position.inSeconds ?? 0,
      position: p,
      imgUrl: widget.subject.images?.large ?? "",
    );
    _syncPlaybackHistory(history);
    var data = widget.subject;
    data.sourceName = source.getName();
    LocalStore.setSubjectCacheAndSource(data);
    LocalStore.addPlaybackHistory(history);
  }

  void _toggleFullScreen(bool isFullScreen) async {
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

  Future<void> _loadDanmaku({
    bool isFirstLoad = true,
    String? keyword,
    Function(String e)? onComplete,
  }) async {
    log('loadDanmaku, isFirstLoad: $isFirstLoad, keyword: $keyword');
    if (_isDanmakuLoading) {
      return;
    }
    bool hasError = false;
    setState(() {
      _isDanmakuLoading = true;
    });
    if (isFirstLoad) {
      var data = await Api.logvar.fetchEpisodeFromLogvar(
        keyword ?? subject.nameCn ?? "",
        (e) {
          hasError = true;
          if (mounted) {
            setState(() {
              _isDanmakuLoading = false;
              onComplete?.call(e.toString());
            });
          }
        },
      );
      log("loadDanmaku: $data");
      safeSetState(() {
        _danmakuList = data;
      });
      double score = 0;
      for (var element in data) {
        var temp = JaroWinklerSimilarity.apply(
          element.animeTitle,
          keyword ?? '',
        );
        if (temp > score && mounted) {
          score = temp;
          setState(() {
            _bestMatch = element;
          });
        }
      }
      if (_bestMatch == null && mounted) {
        setState(() {
          _isDanmakuLoading = false;
          onComplete?.call("player.danmaku_not_exist".tr());
        });
        return;
      }
    }
    if (hasError || _bestMatch == null) {
      return;
    }
    final danmu = await Api.logvar.fetchDammakuSync(
      _bestMatch!.episodes![episodeIndex].episodeId!,
      (e) {
        hasError = true;
        if (mounted) {
          setState(() {
            _isDanmakuLoading = false;
            onComplete?.call("player.danmaku_load_error".tr());
          });
        }
      },
    );
    safeSetState(() {
      _isDanmakuLoading = false;
      _dammaku = danmu;
      onComplete?.call("player.danmaku_loaded".tr());
    });
  }

  void _onDanmakuSourceChange(LogvarEpisode e) {
    if (e.animeId == _bestMatch?.animeId) {
      return;
    }
    setState(() {
      _bestMatch = e;
    });
    _loadDanmaku(isFirstLoad: false, keyword: nameCn);
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
    if (Platform.isAndroid || Platform.isIOS) {
      var info = MediaQuery.of(context);
      setState(() {
        _isTablet =
            Device.get().isTablet && info.orientation == Orientation.landscape;
        //_isFullScreen = info.orientation == Orientation.landscape;
      });
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      setState(() {
        _isTablet = true;
        _isFullScreen = true;
      });
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _loadHistory();
    _fetchEpisode();
    _isTablet = Device.get().isTablet;
    WidgetsBinding.instance.addObserver(this);
    _fetchMediaEpisode().then(
      (value) => _fetchViewInfo(position: historyPosition),
    );
    super.initState();
  }

  @override
  void dispose() {
    _storeLocalHistory();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // _controller?.dispose();
    _playerNotifier.value?.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    log("didRequestAppExit");
    _storeLocalHistory();
    return super.didRequestAppExit();
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

  Widget _buildPlayer({
    required bool isFullScreen,
    required Function(bool isFullScreen) onFullScreenChanged,
    required Function() onBackPressed,
    Function()? onMsgTab,
  }) {
    return Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: Container(
        color: Colors.black,
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: CapVideoPlayerKit(
            title: widget.nameCn,
            subTitle: _episode?.data?[episodeIndex].nameCn,
            isloading: isloading,
            playerNotifier: _playerNotifier,
            isFullScreen: isFullScreen,
            currentEpisodeIndex: episodeIndex,
            dammaku: _dammaku,
            isTablet: _isTablet,
            isInputting: _isInputting,
            episodeList: _episode?.data?.map((e) => e.nameCn!).toList() ?? [],
            onError: (error) => setState(() {
              msg = error.toString();
              isloading = false;
              _logger.e("player.error: $msg");
            }),
            onEpisodeSelected: (index) => _onEpisodeSelected(index),
            onNextTab: () {
              if (isloading ||
                  episodeIndex + 1 >
                      _detail!.lines![lineIndex].episodes!.length - 1) {
                return;
              }
              setState(() {
                ++episodeIndex;
              });
              _fetchViewInfo();
            },
            onFullScreenChanged: (f) {
              onFullScreenChanged(f);
            },
            onBackPressed: () {
              onBackPressed();
            },
            onPositionChanged: (p) {
              _position = p;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      color: Platform.isLinux || Platform.isMacOS || Platform.isWindows
          ? Theme.of(context).scaffoldBackgroundColor
          : null,
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
                  setState(() {
                    _isInputting = true;
                  });
                  //弹幕选择sheet
                  showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                ).copyWith(top: 10),
                                child: Center(
                                  child: TextFormField(
                                    textInputAction: .search,
                                    initialValue: _danmakuKeyword,
                                    decoration: InputDecoration(
                                      hintText: 'player.danmaku_search_hint'
                                          .tr(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onFieldSubmitted: (value) async {
                                      if (value.isEmpty) {
                                        return;
                                      }
                                      setState(() {});
                                      await _loadDanmaku(
                                        isFirstLoad: true,
                                        keyword: value,
                                      );
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              if (_isDanmakuLoading)
                                Padding(
                                  padding: .only(top: 3),
                                  child: LinearProgressIndicator(),
                                ),
                              Expanded(
                                child:
                                    (_danmakuList == null ||
                                        _danmakuList!.isEmpty)
                                    ? Center(
                                        child: Text(
                                          'player.no_danmaku_sheet_text'.tr(),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _danmakuList?.length ?? 0,
                                        separatorBuilder: (context, index) =>
                                            Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            selected:
                                                _bestMatch?.animeId ==
                                                _danmakuList?[index].animeId,
                                            title: Text(
                                              _danmakuList?[index].animeTitle ??
                                                  '',
                                            ),
                                            subtitle: Text(
                                              _danmakuList?[index].animeTitle ??
                                                  '',
                                            ),
                                            onTap: () {
                                              _onDanmakuSourceChange(
                                                _danmakuList![index],
                                              );
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ).then((onValue) {
                    setState(() {
                      _isInputting = false;
                    });
                  });
                },
                icon: Icon(Icons.subtitles_rounded, color: Colors.grey),
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
                      child: Row(
                        spacing: 10,
                        children: [
                          Text(
                            'player.route_number'.tr(
                              args: [(index + 1).toString()],
                            ),
                          ),

                          if (index == lineIndex)
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcATop,
                              ),
                              child: LottieBuilder.asset(
                                "lib/assets/lottie/playing.json",
                                repeat: true,
                                width: 40,
                              ),
                            ),
                        ],
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
                          nameCn: subject.nameCn!.isNotEmpty
                              ? subject.nameCn!
                              : subject.name ?? '',
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
                        // 弹幕统计
                        AnimatedSize(
                          duration: Duration(milliseconds: 300),
                          child: _dammaku == null
                              ? SizedBox.shrink()
                              : Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    enabled: _dammaku != null,
                                    shape: RoundedRectangleBorder(side: .none),
                                    title: Center(
                                      child: _isDanmakuLoading
                                          ? LinearProgressIndicator()
                                          : Text(
                                              context.tr(
                                                'player.danmaku_statistics',
                                                args: [
                                                  (_danmakuList?.length ?? 0)
                                                      .toString(),
                                                  (_dammaku?.comments?.length ??
                                                          0)
                                                      .toString(),
                                                  (_dammaku?.comments?.length ??
                                                          0)
                                                      .toString(),
                                                ],
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                    ),
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxHeight: 400,
                                        ),
                                        child: ListView.builder(
                                          padding: .zero,
                                          itemCount:
                                              _dammaku?.comments?.length ?? 0,
                                          itemBuilder: (context, index) {
                                            final comment =
                                                _dammaku?.comments?[index];
                                            final time = Duration(
                                              seconds:
                                                  comment?.time?.toInt() ?? 0,
                                            );
                                            return ListTile(
                                              titleAlignment: .center,
                                              leading: Text(
                                                '${time.inMinutes}:${time.inSeconds.remainder(60)}',
                                              ),
                                              title: Text(
                                                comment?.text ?? '',
                                                maxLines: 3,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          title: Text(
                            "player.datasource".tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            source.getName(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          leading: Image.network(
                            width: 50,
                            source.getLogoUrl().contains('http')
                                ? source.getLogoUrl()
                                : 'https://${source.getLogoUrl()}',
                            errorBuilder: (context, error, stackTrace) {
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
                    ? LoadingOrShowMsg(
                        msg: msg,
                        onMsgTab: () {
                          _fetchViewInfo();
                        },
                      )
                    : _episode == null
                    ? _buildFadeEpisodeSection()
                    : GridView.builder(
                        key: PageStorageKey("player_episodes"),
                        padding: EdgeInsets.all(10),
                        itemCount: _episode?.data?.length ?? 0,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemBuilder: (context, index) => ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          selected: episodeIndex == index,
                          onTap: () {
                            if (episodeIndex == index || isloading) {
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
                                    Theme.of(context).colorScheme.primary,
                                    BlendMode.srcATop,
                                  ),
                                  child: LottieBuilder.asset(
                                    "lib/assets/lottie/playing.json",
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
    );
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isTablet
        ? Scaffold(
            key: _globalKey,
            resizeToAvoidBottomInset: false,
            backgroundColor: _showInfo ? null : Colors.black,
            endDrawer:
                Platform.isLinux || Platform.isMacOS || Platform.isWindows
                ? SizedBox(
                    width: 400,
                    child: Theme(data: Theme.of(context), child: _buildInfo()),
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  _buildPlayer(
                    isFullScreen: true,
                    onFullScreenChanged: (f) {
                      if (Platform.isLinux ||
                          Platform.isMacOS ||
                          Platform.isWindows) {
                        _globalKey.currentState?.openEndDrawer();
                      } else {
                        setState(() {
                          _showInfo = f;
                        });
                      }
                    },
                    onBackPressed: () {
                      context.pop();
                    },
                    onMsgTab: () {
                      setState(() {
                        _showInfo = true;
                      });
                    },
                  ),
                  if (Platform.isAndroid || Platform.isIOS)
                    AnimatedSize(
                      duration: Duration(milliseconds: 300),
                      child: _showInfo
                          ? SizedBox(
                              width: 400,
                              child: Theme(
                                data: Theme.of(context),
                                child: _buildInfo(),
                              ),
                            )
                          : SizedBox(),
                    ),
                ],
              ),
            ),
          )
        // 移动端
        : Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: _isFullScreen ? Colors.black : null,
            body: SafeArea(
              child: Center(
                child: PopScope(
                  canPop: !_isFullScreen,
                  onPopInvokedWithResult: (didPop, result) {
                    setState(() {
                      _isFullScreen = false;
                      _toggleFullScreen(false);
                    });
                  },
                  child: Column(
                    children: [
                      //视频播放器
                      _buildPlayer(
                        isFullScreen: _isFullScreen,
                        onFullScreenChanged: (isFullScreen) {
                          setState(() {
                            _isTablet = false;
                            _showInfo = false;
                            _isFullScreen = isFullScreen;
                            _toggleFullScreen(_isFullScreen);
                            log('__isFullScreen:$_isFullScreen');
                          });
                        },
                        onBackPressed: () {
                          if (_isFullScreen) {
                            setState(() {
                              _isFullScreen = false;
                              _toggleFullScreen(false);
                            });
                          } else {
                            context.pop();
                          }
                        },
                      ),
                      //剧集列表
                      if (!_isFullScreen)
                        Flexible(flex: 2, child: _buildInfo()),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
