import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/entity/app_setting.dart';
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
import 'package:holo/util/language_util.dart';
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
  final _globalScaffoldKey = GlobalKey<ScaffoldState>();
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
  bool _isTablet = false;
  String _danmakuKeyword = '';
  DanmakuSetting _danmakuSetting = const DanmakuSetting();
  bool _isEpisodeDrawerOpen = false;
  bool _isSettingDrawerOpen = false;
  bool _isInfoDrawerOpen = false;
  bool _enableAutoFocus = true;
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
          _logger.e("fetchDetail1 error: $e");
          msg = e.toString();
        }),
      );

      if (mounted) {
        setState(() {
          _detail = res;
        });
      }
    } catch (e) {
      _logger.e("fetchDetail2 error: $e");
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
          (e) => safeSetState(() {
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
      safeSetState(() {
        msg = "player.playback_error".tr();
        onComplete?.call(msg);
      });
    } finally {
      safeSetState(() {
        isloading = false;
      });
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
        _logger.e("fetchEpisode error: $e");
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
        _logger.e("savePlaybackHistory error: $e");
      },
    );
  }

  Future<void> _loadDanmaku({
    bool isFirstLoad = true,
    String? keyword,
    Function(String e)? onComplete,
  }) async {
    _logger.i('loadDanmaku, isFirstLoad: $isFirstLoad, keyword: $keyword');
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

  void _loadDanmakuSetting() {
    setState(() {
      _danmakuSetting = LocalStore.getAppSetting().danmakuSetting;
    });
  }

  void _showDanmakuBottomSheet() {
    setState(() {
      _enableAutoFocus = false;
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
                        hintText: 'player.danmaku_search_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _danmakuKeyword = value;
                        });
                      },
                      onFieldSubmitted: (value) async {
                        if (value.isEmpty) {
                          return;
                        }
                        setState(() {});
                        await _loadDanmaku(isFirstLoad: true, keyword: value);
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
                  child: (_danmakuList == null || _danmakuList!.isEmpty)
                      ? Center(child: Text('player.no_danmaku_sheet_text'.tr()))
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
                                _danmakuList?[index].animeTitle ?? '',
                              ),
                              subtitle: Text(
                                _danmakuList?[index].animeTitle ?? '',
                              ),
                              onTap: () {
                                _onDanmakuSourceChange(_danmakuList![index]);
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
        _enableAutoFocus = true;
      });
    });
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
      });
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      setState(() {
        _isTablet = true;
        _isFullScreen = true;
      });
    }
    if (_isTablet) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _loadDanmakuSetting();
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
    _logger.d("didRequestAppExit");
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
    required void Function(bool isFullScreen) onFullScreenChanged,
    required void Function() onBackPressed,
  }) {
    return Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: Container(
        color: Colors.black,
        height: double.infinity,
        width: double.infinity,
        child: ValueListenableBuilder(
          valueListenable: _playerNotifier,
          builder: (context, value, child) {
            return Center(
              child: CapVideoPlayerKit(
                title: widget.nameCn,
                subTitle: _episode?.data?[episodeIndex].nameCn,
                isloading: isloading,
                centerMsg: msg,
                playerNotifier: _playerNotifier,
                isFullScreen: isFullScreen,
                currentEpisodeIndex: episodeIndex,
                dammaku: _dammaku,
                isTablet: _isTablet,
                danmakuSetting: _danmakuSetting,
                enableAutoFocus: _enableAutoFocus,
                onEpisodeTab: () {
                  if (_isTablet ||
                      Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux) {
                    setState(() {
                      _isInfoDrawerOpen = true;
                      _isEpisodeDrawerOpen = false;
                      _isSettingDrawerOpen = false;
                    });
                  } else {
                    setState(() {
                      _isEpisodeDrawerOpen = true;
                      _isInfoDrawerOpen = false;
                      _isSettingDrawerOpen = false;
                    });
                  }
                  _globalScaffoldKey.currentState?.openEndDrawer();
                },
                onSettingTab: () {
                  setState(() {
                    _isSettingDrawerOpen = true;
                    _isEpisodeDrawerOpen = false;
                    _isInfoDrawerOpen = false;
                  });
                  _globalScaffoldKey.currentState?.openEndDrawer();
                },
                onError: (error) => setState(() {
                  msg = error.toString();
                  isloading = false;
                  _logger.e("player.error: $msg");
                }),

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
            );
          },
        ),
      ),
    );
  }

  /// 简介
  Widget _buildSummary() {
    return Padding(
      padding: .all(12),
      child: CustomScrollView(
        slivers: [
          // 简介卡片
          SliverToBoxAdapter(
            child: MediaCard(
              id: "player_${subject.id!}",
              imageUrl: subject.images?.large!,
              title: getTitle(subject),
              genre: subject.metaTags?.join('/'),
              episode: subject.eps ?? 0,
              rating: subject.rating?.score,
              height: 180,
              airDate: subject.date,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          // 数据源
          SliverToBoxAdapter(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              title: Text(
                "player.datasource".tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                source.getName(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              leading: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 100),
                child: Image.network(
                  width: double.infinity,
                  source.getLogoUrl().contains('http')
                      ? source.getLogoUrl()
                      : 'https://${source.getLogoUrl()}',
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error);
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          // 弹幕
          SliverToBoxAdapter(
            child: AnimatedSize(
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
                      child: ListTile(
                        title: _isDanmakuLoading
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
            ),
          ),
        ],
      ),
    );
  }

  /// 剧集列表
  Widget _buildEpisode() {
    return msg.isNotEmpty
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
            ),
          );
  }

  Widget _buildInfo() {
    return SizedBox(
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
                  _showDanmakuBottomSheet();
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
              children: [_buildSummary(), _buildEpisode()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenre() {
    bool isSelected = false;
    bool isFilterSelected = false;
    return Wrap(
      children: [
        InputChip(label: Text('input_chip')),
        ChoiceChip(
          label: Text('choineChip'),
          selected: isSelected,
          onSelected: (bool value) {
            setState(() {
              isSelected = value;
            });
          },
        ),
        FilterChip(
          label: Text('filterChip'),
          onSelected: (bool value) {
            setState(() {
              isFilterSelected = value;
            });
          },
        ),
        ActionChip(
          label: Text('actionChip'),
          onPressed: () {
            _logger.d("actionChip pressed");
          },
        ),
      ],
    );
  }

  Widget _buildEpisodeDrawer() {
    final eps = _episode?.data;
    return SizedBox.expand(
      child: ListView.builder(
        key: const PageStorageKey("player_episodes_list"),
        itemCount: eps?.length ?? 0,
        itemBuilder: (context, index) {
          return ListTile(
            selected: index == episodeIndex,
            horizontalTitleGap: 0,
            leading: Text(
              (index + 1).toString(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            title: Text(eps?[index].nameCn ?? ""),
            trailing: episodeIndex == index
                ? Container(
                    constraints: BoxConstraints(maxWidth: 80),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcATop,
                      ),
                      child: LottieBuilder.asset(
                        "lib/assets/lottie/playing2.json",
                        repeat: true,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              _onEpisodeSelected(index);
            },
          );
        },
      ),
    );
  }

  ///  弹幕设置
  Widget _buildDanmakuSettingDrawer({
    required DanmakuSetting setting,
    void Function(DanmakuSetting setting)? onSettingChanged,
  }) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: TextFormField(
                initialValue: setting.filterWords,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  onSettingChanged?.call(setting.copyWith(filterWords: value));
                },
                decoration: InputDecoration(
                  labelText: context.tr(
                    'component.cap_video_player.danmaku_filter_keywords',
                  ),
                  hintStyle: TextStyle(fontSize: 10),
                  hintText: context.tr(
                    'component.cap_video_player.danmaku_filter_hint',
                  ),
                ),
              ),
            ),

            ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(
                      'component.cap_video_player.danmaku_offset_adjustment',
                    ),
                  ),
                  Tooltip(
                    message: context.tr(
                      'component.cap_video_player.danmaku_offset_tooltip',
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                context.tr(
                  'component.cap_video_player.current_offset',
                  args: [setting.danmakuOffset.toString()],
                ),
              ),

              leading: IconButton(
                onPressed: () {
                  onSettingChanged?.call(
                    setting.copyWith(danmakuOffset: setting.danmakuOffset - 1),
                  );
                },
                icon: const Icon(Icons.exposure_neg_1),
              ),
              trailing: IconButton(
                onPressed: () {
                  onSettingChanged?.call(
                    setting.copyWith(danmakuOffset: setting.danmakuOffset + 1),
                  );
                },
                icon: const Icon(Icons.exposure_plus_1),
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.hide_top_danmaku'),
              ),
              trailing: Switch(
                value: setting.hideTop,
                onChanged: (value) {
                  onSettingChanged?.call(setting.copyWith(hideTop: value));
                },
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.hide_bottom_danmaku'),
              ),
              trailing: Switch(
                value: setting.hideBottom,
                onChanged: (value) {
                  onSettingChanged?.call(setting.copyWith(hideBottom: value));
                },
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.hide_scroll_danmaku'),
              ),
              trailing: Switch(
                value: setting.hideScroll,
                onChanged: (value) {
                  onSettingChanged?.call(setting.copyWith(hideScroll: value));
                },
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.massive_danmaku_mode'),
              ),
              subtitle: Text(
                context.tr(
                  'component.cap_video_player.massive_danmaku_subtitle',
                ),
              ),
              trailing: Switch(
                value: setting.massiveMode,
                onChanged: (value) {
                  onSettingChanged?.call(setting.copyWith(massiveMode: value));
                },
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.danmaku_opacity'),
              ),
              leading: null,
              subtitle: Row(
                children: [
                  Text('${(setting.opacity * 100).round()}%'),
                  Expanded(
                    child: Slider(
                      min: 0.1,
                      max: 1.0,
                      value: setting.opacity,
                      onChanged: (value) {
                        onSettingChanged?.call(
                          setting.copyWith(opacity: value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.display_area'),
              ),
              subtitle: Row(
                children: [
                  Text('${(setting.area * 100).round()}%'),
                  Expanded(
                    child: Slider(
                      min: 0.1,
                      max: 1.0,
                      value: setting.area,
                      onChanged: (value) {
                        onSettingChanged?.call(setting.copyWith(area: value));
                      },
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                context.tr('component.cap_video_player.danmaku_font_size'),
              ),
              subtitle: Row(
                children: [
                  Text('${(setting.fontSize).round()}'),
                  Expanded(
                    child: Slider(
                      min: 10.0,
                      max: 50.0,
                      value: setting.fontSize,
                      onChanged: (value) {
                        onSettingChanged?.call(
                          setting.copyWith(fontSize: value),
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
    );
  }

  /// 抽屉
  Widget _buildDrawer() {
    if (_isEpisodeDrawerOpen) {
      return _buildEpisodeDrawer();
    } else if (_isSettingDrawerOpen) {
      return _buildDanmakuSettingDrawer(
        setting: _danmakuSetting,
        onSettingChanged: (setting) => safeSetState(() {
          _danmakuSetting = setting;
        }),
      );
    } else if (_isInfoDrawerOpen && _isTablet) {
      return _buildInfo();
    } else {
      return SizedBox.shrink();
    }
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isTablet
        // PC端，包含平板
        ? Scaffold(
            key: _globalScaffoldKey,
            resizeToAvoidBottomInset: false,
            onEndDrawerChanged: (isOpened) {
              setState(() {
                _enableAutoFocus = !isOpened;
              });
            },
            endDrawer: Drawer(width: 400, child: _buildDrawer()),
            body: SafeArea(
              child: _buildPlayer(
                isFullScreen: true,
                onFullScreenChanged: (isFullScreen) {
                  setState(() {
                    _isFullScreen = isFullScreen;
                  });
                  _toggleFullScreen(isFullScreen);
                },
                onBackPressed: () => context.pop(),
              ),
            ),
          )
        // 移动端,不包含平板
        : Scaffold(
            key: _globalScaffoldKey,
            resizeToAvoidBottomInset: false,
            endDrawer: Drawer(width: 300, child: _buildDrawer()),
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
                            _isFullScreen = isFullScreen;
                            _toggleFullScreen(_isFullScreen);
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
