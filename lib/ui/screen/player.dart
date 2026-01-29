import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/api/setting_api.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/entity/episode.dart';
import 'package:holo/entity/logvar_episode.dart';
import 'package:holo/entity/media.dart' as media_entity;
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
import 'package:media_kit/media_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:window_manager/window_manager.dart';

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
  media_entity.Detail? _detail;
  bool isloading = false;
  int historyPosition = 0;
  String? playUrl;
  bool _isActive = true;
  List<LogvarEpisode>? _danmakuList;
  LogvarEpisode? _bestMatch;
  Danmu? _dammaku;
  bool _isDanmakuLoading = false;
  bool _showEpisodeList = true;
  bool _isTablet = false;
  late final String nameCn = widget.nameCn;
  late final String mediaId = widget.mediaId;
  late final SourceService source = widget.source;
  final Player _kitPlayer = Player();
  late FocusNode _focusNode;
  late final TabController _tabController = TabController(
    vsync: this,
    length: 2,
  );

  /// 键盘事件处理
  void _handleKeyEvent(KeyEvent event) {
    log("${event.logicalKey}");

    if ((event is KeyDownEvent) &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.tab:
          break;
        case LogicalKeyboardKey.keyQ:
          setState(() {
            _showEpisodeList = !_showEpisodeList;
          });
          break;
        case LogicalKeyboardKey.space:
          _kitPlayer.playOrPause();
          break;
        case LogicalKeyboardKey.escape:
          windowManager.setFullScreen(false);
          break;
        case LogicalKeyboardKey.keyF:
          windowManager.isFullScreen().then((isfu) {
            windowManager.setFullScreen(!isfu);
          });
          break;
        case LogicalKeyboardKey.arrowRight:
          _kitPlayer.seek(_kitPlayer.state.position + Duration(seconds: 5));
          break;
        case LogicalKeyboardKey.arrowLeft:
          _kitPlayer.seek(_kitPlayer.state.position - Duration(seconds: 5));
          break;
        case LogicalKeyboardKey.arrowUp:
          _kitPlayer.setVolume((_kitPlayer.state.volume + 5).clamp(0, 100));
          break;
        case LogicalKeyboardKey.arrowDown:
          _kitPlayer.setVolume((_kitPlayer.state.volume - 5).clamp(0, 100));
          break;
      }
    }
  }

  /// 获取剧集信息
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

  /// 获取播放信息
  Future<void> _fetchViewInfo({
    int position = 0,
    Function(String e)? onComplete,
  }) async {
    msg = "";
    isloading = true;
    try {
      if (_detail != null) {
        await _kitPlayer.pause();

        lineIndex = lineIndex.clamp(0, _detail!.lines!.length - 1);
        episodeIndex = episodeIndex.clamp(
          0,
          _detail!.lines![lineIndex].episodes!.length - 1,
        );
        _loadDanmaku(
          isFirstLoad: true,
          onComplete: (e) {
            // ScaffoldMessenger.of(
            //   context,
            // ).showSnackBar(SnackBar(content: Text(e), showCloseIcon: true));
          },
        );
        final newUrl = await source.fetchPlaybackUrl(
          _detail!.lines![lineIndex].episodes![episodeIndex],
          (e) => setState(() {
            log("fetchView error: $e");
            msg = "player.playback_error".tr();
            onComplete?.call(msg);
          }),
        );
        playUrl = newUrl;
        // final newController = VideoPlayerController.networkUrl(
        //   Uri.parse(newUrl ?? ""),
        // );
        log('new url: $newUrl');
        await _kitPlayer.open(Media(newUrl ?? ""));
        log('seek to: $position');
        await _kitPlayer.play();

        if (mounted) {
          setState(() {
            msg = "";
            _isActive ? _kitPlayer.play() : _kitPlayer.pause();
          });
        }
        _kitPlayer.stream.duration.first.then((value) {
          _kitPlayer.seek(Duration(seconds: position));
        });
      }
    } catch (e) {
      log("fetchView error: $e");
      if (mounted) {
        setState(() {
          msg = "player.playback_error".tr();
          onComplete?.call(msg);
        });
      }
    } finally {
      isloading = false;
    }
  }

  /// 线路选择
  void _onLineSelected(int index) {
    if (index == lineIndex) {
      return;
    }
    setState(() {
      lineIndex = index;
    });
    _fetchViewInfo();
  }

  /// 剧集选择
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

  /// 加载播放历史
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

  /// 获取剧集列表
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

  /// 存储播放历史
  void _storeLocalHistory() async {
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
      position: _kitPlayer.state.position.inSeconds,
      imgUrl: widget.subject.images?.large ?? "",
    );
    _syncPlaybackHistory(history);
    var data = widget.subject;
    data.sourceName = source.getName();
    LocalStore.setSubjectCacheAndSource(data);
    LocalStore.addPlaybackHistory(history);
  }

  /// 切换全屏
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

  /// 同步播放历史
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

  /// 加载弹幕
  void _loadDanmaku({
    bool isFirstLoad = true,
    String? keyword,
    Function(String e)? onComplete,
  }) async {
    if (_isDanmakuLoading) {
      return;
    }
    bool hasError = false;
    setState(() {
      _isDanmakuLoading = true;
      // _danmuMsg = "player.danmaku_loading".tr();
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
          _isDanmakuLoading = false;
          onComplete?.call("player.danmaku_not_exist".tr());
        });
        return;
      }
    }
    if (hasError) {
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
    if (mounted) {
      setState(() {
        _isDanmakuLoading = false;
        _dammaku = danmu;
        onComplete?.call("player.danmaku_loaded".tr());
      });
    }
  }

  /// 弹幕源选择
  void _onDanmakuSourceChange(LogvarEpisode e) {
    if (e.animeId == _bestMatch?.animeId) {
      return;
    }
    setState(() {
      _bestMatch = e;
    });
    _loadDanmaku(isFirstLoad: false);
  }

  /// 应用生命周期变化处理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        _isActive = false;
      });
      _kitPlayer.pause();
      _storeLocalHistory();
    }
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isActive = true;
      });
      _kitPlayer.play();
    }
    if (state == AppLifecycleState.inactive) {
      _storeLocalHistory();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangeDependencies() {
    _storeLocalHistory();
    log("didChangeDependencies");
    //log('isTablet:${Device.get().isTablet}');
    if (Platform.isAndroid || Platform.isIOS) {
      var info = MediaQuery.of(context);
      setState(() {
        _isTablet =
            Device.get().isTablet && info.orientation == Orientation.landscape;
        _isFullScreen = info.orientation == Orientation.landscape;
      });
    }
    if (Platform.isWindows || Platform.isMacOS) {
      setState(() {
        _isTablet = true;
        _isFullScreen = true;
      });
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _focusNode = FocusNode();
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
    _kitPlayer.dispose();
    _storeLocalHistory();
    SettingApi.updateSetting(() {}, (_) {});
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _focusNode.dispose();
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
          child: !isloading
              ? CapVideoPlayer(
                  title: widget.nameCn,
                  subTitle: _episode?.data?[episodeIndex].nameCn,
                  isloading: isloading,
                  kitPlayer: _kitPlayer,
                  isFullScreen: isFullScreen,
                  currentEpisodeIndex: episodeIndex,
                  dammaku: _dammaku,
                  isTablet: _isTablet,
                  episodeList:
                      _episode?.data?.map((e) => e.name!).toList() ?? [],
                  onError: (error) => setState(() {
                    msg = error.toString();
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
                )
              : LoadingOrShowMsg(
                  msg: msg,
                  backgroundColor: Colors.black,
                  onMsgTab: onMsgTab,
                ),
        ),
      ),
    );
  }

  Widget _buildEpisodeItem(int index) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        _episode?.data?[index].nameCn ?? "player.no_episode_name".tr(),
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
    );
  }

  Widget _buildEpisode() {
    return Column(
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
                //弹幕选择sheet
                showModalBottomSheet(
                  context: context,
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
                                child: TextField(
                                  textInputAction: .search,
                                  decoration: InputDecoration(
                                    hintText: 'player.danmaku_search_hint'.tr(),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    if (value.isEmpty) {
                                      return;
                                    }
                                    _loadDanmaku(
                                      isFirstLoad: true,
                                      keyword: value,
                                    );
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
                              child: StatefulBuilder(
                                builder: (context, setState) =>
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
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
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
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: _dammaku != null ? 38 : 0,
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _isDanmakuLoading
                              ? LinearProgressIndicator()
                              : Text(
                                  context.tr(
                                    'player.danmaku_statistics',
                                    args: [
                                      (_danmakuList?.length ?? 0).toString(),
                                      (_dammaku?.comments?.length ?? 0)
                                          .toString(),
                                      (_dammaku?.comments?.length ?? 0)
                                          .toString(),
                                    ],
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                  : _isTablet
                  ? ListView.builder(
                      key: PageStorageKey("player_episodes_list"),
                      padding: EdgeInsets.all(10),
                      itemCount: _episode?.data?.length ?? 0,
                      itemBuilder: (context, index) => _buildEpisodeItem(index),
                    )
                  : GridView.builder(
                      key: PageStorageKey("player_episodes_grid"),
                      padding: EdgeInsets.all(10),
                      itemCount: _episode?.data?.length ?? 0,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                      ),
                      itemBuilder: (context, index) => _buildEpisodeItem(index),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isTablet
        ? Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: _showEpisodeList ? null : Colors.black,
            body: KeyboardListener(
              onKeyEvent: _handleKeyEvent,
              focusNode: _focusNode,
              autofocus: true,
              child: SafeArea(
                child: Row(
                  children: [
                    _buildPlayer(
                      isFullScreen: !_showEpisodeList,
                      onFullScreenChanged: (_) {
                        setState(() {
                          _showEpisodeList = !_showEpisodeList;
                        });
                      },
                      onBackPressed: () {
                        context.pop();
                      },
                      onMsgTab: () {
                        setState(() {
                          _showEpisodeList = true;
                        });
                      },
                    ),
                    AnimatedSize(
                      duration: Duration(milliseconds: 300),
                      child: _showEpisodeList
                          ? SizedBox(
                              width: 300,
                              child: Theme(
                                data: Theme.of(context),
                                child: _buildEpisode(),
                              ),
                            )
                          : SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Scaffold(
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
                      _buildPlayer(
                        isFullScreen: _isFullScreen,
                        onFullScreenChanged: (isFullScreen) {
                          setState(() {
                            _isTablet = false;
                            _showEpisodeList = false;
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
                      ),
                      //剧集列表
                      if (!_isFullScreen)
                        Flexible(flex: 2, child: _buildEpisode()),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
