import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/playback_api.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/entity/episode_item.dart';
import 'package:holo/entity/logvar_episode.dart';
import 'package:holo/entity/media.dart' as holo_media;
import 'package:holo/entity/person.dart';
import 'package:holo/entity/playback_history.dart';
import 'package:holo/entity/subject_item.dart';
import 'package:holo/entity/subject_relation.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/component/cap_video_player_kit.dart';
import 'package:holo/ui/component/circle_avatar_with_text.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:holo/util/jaro_winkler_similarity.dart';
import 'package:holo/util/local_storage.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final String mediaId;
  final SubjectItem subject;
  final SourceService source;
  final String nameCn;
  final bool isLove;
  final List<Person> person;
  final List<Character> character;
  final List<SubjectRelation> relation;
  const PlayerScreen({
    super.key,
    required this.mediaId,
    required this.subject,
    required this.source,
    required this.nameCn,
    this.isLove = false,
    this.person = const [],
    this.character = const [],
    this.relation = const [],
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _globalScaffoldKey =
      GlobalKey<ScaffoldState>();
  final Logger _logger = Logger();
  late SubjectItem subject = widget.subject;
  bool _isFullScreen = false;
  String msg = "";
  int episodeIndex = 0;
  int lineIndex = 0;
  List<Episode> _episode = [];
  holo_media.Detail? _detail;
  bool isLoading = false;
  int historyPosition = 0;
  String? playUrl;
  bool _isActive = true;
  List<LogvarEpisode>? _danmakuList;
  LogvarEpisode? _bestDanmakuSourceMatch;
  Danmu? _dammaku;
  bool _isDanmakuLoading = false;
  bool _isTablet = false;
  String _danmakuKeyword = '';
  DanmakuSetting _danmakuSetting = const DanmakuSetting();
  bool _isEpisodeDrawerOpen = false;
  bool _isSettingDrawerOpen = false;
  bool _isInfoDrawerOpen = false;
  bool _enableAutoFocus = true;
  int _danmakuOffset = 0;
  late final String nameCn = widget.nameCn;
  late final String mediaId = widget.mediaId;
  late final SourceService source = widget.source;
  final _playerNotifier = ValueNotifier<VideoPlayerController?>(null);
  Duration _position = .zero;
  Timer? _playbackHistorySyncTimer;
  late final TabController _tabController = TabController(
    vsync: this,
    length: 2,
  );

  Future<void> _fetchMediaEpisode() async {
    isLoading = true;
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
      isLoading = false;
    }
  }

  Future<void> _fetchViewInfo({
    int position = 0,
    bool loadDanmaku = true,
    void Function(String e)? onComplete,
  }) async {
    safeSetState(() {
      msg = "";
      isLoading = true;
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
        _playerNotifier.value?.pause();
        _playerNotifier.value?.dispose();
        _playerNotifier.value = null;
        final newUrl = await source.fetchPlaybackUrl(
          _detail!.lines![lineIndex].episodes![episodeIndex],
          (e) => safeSetState(() {
            _logger.e("fetchView error: $e");
            msg = "player.playback_error".tr();
            isLoading = false;
            onComplete?.call(msg);
          }),
        );
        if (newUrl == null || newUrl.isEmpty) {
          safeSetState(() {
            msg = "player.playback_error".tr();
            isLoading = false;
            onComplete?.call(msg);
          });
          return;
        }
        playUrl = newUrl;
        final newController = VideoPlayerController.networkUrl(
          Uri.parse(newUrl),
        );
        await newController.initialize();

        _playerNotifier.value = newController;
        safeSetState(() {
          msg = '';
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
        isLoading = false;
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
    final history = LocalStorage.getPlaybackHistoryById(widget.subject.id);
    if (history != null && mounted) {
      setState(() {
        episodeIndex = history.episodeIndex;
        lineIndex = history.lineIndex;
        historyPosition = history.position;
      });
    }
  }

  void _fetchEpisode() async {
    final res = await Api.bangumi.fetchEpisode(
      widget.subject.id,
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

  void _storeLocalHistory({bool syncNow = false}) async {
    if (playUrl == null) {
      return;
    }
    final p =
        (await _playerNotifier.value?.position ?? Duration.zero).inSeconds;
    if (p <= 0) {
      return;
    }
    PlaybackHistory history = PlaybackHistory(
      subId: widget.subject.id,
      title: nameCn,
      episodeIndex: episodeIndex,
      lineIndex: lineIndex,
      lastPlaybackAt: DateTime.now(),
      createdAt: DateTime.now(),
      // position: _controller?.value.position.inSeconds ?? 0,
      position: p,
      imgUrl: widget.subject.images.large ?? "",
    );
    _syncPlaybackHistory(history, syncNow: syncNow);
    var data = widget.subject;
    LocalStorage.setSubjectCache(data);
    LocalStorage.addPlaybackHistory(history);
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

  void _syncPlaybackHistory(PlaybackHistory history, {bool syncNow = false}) {
    if (syncNow) {
      PlayBackApi.savePlaybackHistory(
        history,
        () {
          history.isSync = true;
        },
        (e) {
          _logger.e("savePlaybackHistory error: $e");
        },
      );
    } else {
      _playbackHistorySyncTimer?.cancel();
      _playbackHistorySyncTimer = Timer.periodic(
        const Duration(seconds: 3),
        (timer) => _syncPlaybackHistory(history),
      );
    }
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
        keyword ?? subject.title,
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
            _bestDanmakuSourceMatch = element;
          });
        }
      }
      if (_bestDanmakuSourceMatch == null && mounted) {
        setState(() {
          _isDanmakuLoading = false;
          onComplete?.call("player.danmaku_not_exist".tr());
        });
        return;
      }
    }
    if (hasError || _bestDanmakuSourceMatch == null) {
      return;
    }
    var remainder = episodeIndex.remainder(_episode.length);
    if (remainder >= (_bestDanmakuSourceMatch?.episodes?.length ?? 0)) {
      safeSetState(() {
        _isDanmakuLoading = false;
        onComplete?.call(
          "${_bestDanmakuSourceMatch?.animeTitle ?? ""} - ${"player.danmaku_not_exist".tr()}",
        );
      });
      return;
    }
    final danmu = await Api.logvar.fetchDammakuSync(
      _bestDanmakuSourceMatch!.episodes![remainder].episodeId!,
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
    if (e.animeId == _bestDanmakuSourceMatch?.animeId) {
      return;
    }
    setState(() {
      _bestDanmakuSourceMatch = e;
    });
    _loadDanmaku(
      isFirstLoad: false,
      keyword: nameCn,
      onComplete: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e), showCloseIcon: true));
      },
    );
  }

  void _loadDanmakuSetting() {
    setState(() {
      _danmakuSetting = LocalStorage.getAppSetting().danmakuSetting.copyWith(
        danmakuOffset: 0,
      );
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
          builder: (context, s) {
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
                        hint: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('player.danmaku_search_hint'.tr()),
                        ),
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
                        s(() {});
                        await _loadDanmaku(isFirstLoad: true, keyword: value);
                        s(() {});
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
                                  _bestDanmakuSourceMatch?.animeId ==
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

  void _showPersonDetail({
    required String image,
    required String name,
    required String role,
    required int bangumiId,
    bool isCharacter = true,
    String cv = '',
    String summary = '',
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(12),
          child: Stack(
            children: [
              Row(
                spacing: 4,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        width: double.infinity,
                        height: double.infinity,
                        image,
                        fit: BoxFit.fitHeight,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(size: 70, Icons.error)),
                      ),
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          if (name.isNotEmpty)
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          if (cv.isNotEmpty)
                            Text(
                              'CV: $cv',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          if (role.isNotEmpty)
                            Text(
                              role,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),

                          if (summary.isNotEmpty)
                            Text(
                              summary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right:
                    MediaQuery.of(context).orientation == Orientation.landscape
                    ? 20
                    : 6,
                top: 6,
                child: IconButton(
                  tooltip: "Link to Bangumi",
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse(
                        'https://bangumi.tv/${isCharacter ? 'character' : 'person'}/$bangumiId',
                      ),
                    );
                  },
                  icon: Icon(Icons.link_rounded),
                ),
              ),
            ],
          ),
        );
      },
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
        child: Center(
          child: CapVideoPlayerKit(
            title: widget.nameCn,
            subTitle: _episode.isNotEmpty ? _episode[episodeIndex].title : '',
            isLoading: isLoading,
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
                _tabController.animateTo(1);
              } else {
                setState(() {
                  _isEpisodeDrawerOpen = true;
                  _isInfoDrawerOpen = false;
                  _isSettingDrawerOpen = false;
                });
              }
              if (_globalScaffoldKey.currentState?.isEndDrawerOpen ?? false) {
                _globalScaffoldKey.currentState?.closeEndDrawer();
              } else {
                _globalScaffoldKey.currentState?.openEndDrawer();
              }
            },
            onSettingTab: () {
              setState(() {
                _isSettingDrawerOpen = true;
                _isEpisodeDrawerOpen = false;
                _isInfoDrawerOpen = false;
              });
              if (_globalScaffoldKey.currentState?.isEndDrawerOpen ?? false) {
                _globalScaffoldKey.currentState?.closeEndDrawer();
              } else {
                _globalScaffoldKey.currentState?.openEndDrawer();
              }
            },
            onError: (error) => setState(() {
              msg = error.toString();
              isLoading = false;
              _logger.e("player.error: $msg");
            }),

            onNextTab: () {
              if (isLoading ||
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

  /// 简介
  Widget _buildSummary() {
    return Padding(
      padding: .all(12),
      child: CustomScrollView(
        slivers: [
          // 简介卡片
          SliverToBoxAdapter(
            child: MediaCard(
              id: "player_${subject.id}",
              imageUrl: subject.images.large!,
              title: subject.title,
              genre: subject.metaTags.join('/'),
              episode: subject.totalEpisodes,
              rating: subject.rating,
              ratingCount: subject.ratingCount,
              height: 180,
              airDate: subject.airDate,
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
              leading: SizedBox(
                width: 100,
                child: Center(
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

          // 角色
          if (widget.character.isNotEmpty)
            _buildPersonGrid(
              title: "player.character".tr(),
              name2Image: {
                for (var e in widget.character)
                  e.name ?? '': e.images?.grid ?? "",
              },
              onTap: (index) => _showPersonDetail(
                bangumiId: widget.character[index].id!,
                image: widget.character[index].images?.large ?? "",
                name: widget.character[index].name ?? "",
                role: widget.character[index].relation ?? "",
                summary: widget.character[index].summary ?? "",
                cv:
                    widget.character[index].actors
                        ?.map((a) => a.name ?? "")
                        .join('·') ??
                    "",
              ),
            ),

          // 人物
          if (widget.person.isNotEmpty)
            _buildPersonGrid(
              title: "player.person".tr(),
              name2Image: {
                for (var e in widget.person) e.name ?? '': e.images?.grid ?? "",
              },
              onTap: (index) => _showPersonDetail(
                bangumiId: widget.person[index].id!,
                image: widget.person[index].images?.large ?? "",
                name: widget.person[index].name ?? "",
                role: widget.person[index].relation ?? "",
                isCharacter: false,
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
        : GridView.builder(
            key: PageStorageKey("player_episodes"),
            padding: EdgeInsets.all(10),
            itemCount: _episode.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, index) => Material(
              clipBehavior: .antiAlias,
              color: Colors.transparent,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),

                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer,
                selected: episodeIndex == index,
                onTap: () {
                  if (episodeIndex == index || isLoading) {
                    return;
                  }
                  _onEpisodeSelected(index);
                },
                subtitle: Text(
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  _episode[index].title.isNotEmpty
                      ? _episode[index].title
                      : "player.no_episode_name".tr(),
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
          );
  }

  /// 剧集信息
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
                color: Colors.grey,
                onPressed: () {
                  _showDanmakuBottomSheet();
                },
                icon: Icon(Icons.subtitles_rounded),
              ),
              // 路线选择
              PopupMenuButton(
                tooltip: 'player.route_selection'.tr(),
                iconColor: Colors.grey,
                icon: Icon(Icons.source_rounded),
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
                        _onLineSelected(index);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSummary(), _buildEpisode()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeDrawer() {
    final eps = _episode;
    return SizedBox.expand(
      child: ListView.builder(
        key: const PageStorageKey("player_episodes_list"),
        itemCount: eps.length,
        itemBuilder: (context, index) {
          return ListTile(
            selected: index == episodeIndex,
            horizontalTitleGap: 0,
            leading: Text(
              (index + 1).toString(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            title: Text(eps[index].title),
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
                  hint: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr(
                        'component.cap_video_player.danmaku_filter_hint',
                      ),
                    ),
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
              // 弹幕偏移量
              subtitle: Text(
                context.tr(
                      'component.cap_video_player.current_offset',
                      args: [''],
                    ) +
                    _danmakuOffset.toString(),
              ),
              // 调整弹幕偏移量-1
              leading: IconButton(
                onPressed: () {
                  _logger.d('current offset:${setting.danmakuOffset}');
                  safeSetState(() {
                    _danmakuOffset--;
                  });
                  onSettingChanged?.call(
                    setting.copyWith(danmakuOffset: _danmakuOffset),
                  );
                },
                icon: const Icon(Icons.exposure_neg_1),
              ),
              // 调整弹幕偏移量+1
              trailing: IconButton(
                onPressed: () {
                  safeSetState(() {
                    _danmakuOffset++;
                  });
                  onSettingChanged?.call(
                    setting.copyWith(danmakuOffset: _danmakuOffset),
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

  /// 角色/人物网格
  SliverToBoxAdapter _buildPersonGrid({
    required String title,
    Map<String, String> name2Image = const {},
    void Function(int index)? onTap,
  }) {
    return SliverToBoxAdapter(
      child: Card(
        child: Container(
          padding: .all(6),
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollBehavior().copyWith(
                    scrollbars: !(Platform.isAndroid || Platform.isIOS),
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: name2Image.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 12,
                      childAspectRatio: 4 / 3,
                    ),
                    itemBuilder: (context, index) {
                      return CircleAvatarWithText(
                        imageUrl: name2Image.values.elementAt(index),
                        username: name2Image.keys.elementAt(index),
                        onTap: () {
                          onTap?.call(index);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        _isActive = false;
      });
      _storeLocalHistory(syncNow: true);
    }
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isActive = true;
      });
    }
    if (state == AppLifecycleState.inactive) {
      _storeLocalHistory(syncNow: true);
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
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.setTitle(widget.nameCn);
    }
    _loadDanmakuSetting();
    _loadHistory();
    _fetchEpisode();
    _isTablet = Device.get().isTablet;
    WidgetsBinding.instance.addObserver(this);
    _fetchMediaEpisode().then(
      (value) => _fetchViewInfo(position: historyPosition),
    );
    // 设置播放器页面的状态栏样式（深色模式）
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light, // 浅色图标
        statusBarBrightness: Brightness.dark, // 深色状态栏
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      PackageInfo.fromPlatform().then((info) {
        windowManager.setTitle(info.appName);
      });
    }
    _storeLocalHistory(syncNow: true);
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // _controller?.dispose();
    _playerNotifier.value?.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    _logger.d("didRequestAppExit");
    _storeLocalHistory(syncNow: true);
    return super.didRequestAppExit();
  }

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
            endDrawerEnableOpenDragGesture: false,
            endDrawer: Drawer(width: 400, child: _buildDrawer()),
            body: SafeArea(
              child: SizedBox.expand(
                child: Row(
                  children: [
                    _buildPlayer(
                      isFullScreen: true,
                      onFullScreenChanged: (isFullScreen) {
                        setState(() {
                          _isFullScreen = isFullScreen;
                        });
                        _toggleFullScreen(isFullScreen);
                      },
                      onBackPressed: () {
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux) {
                          windowManager.setFullScreen(false);
                        }
                        context.pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          )
        // 移动端,不包含平板
        : Scaffold(
            key: _globalScaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Colors.black,
              automaticallyImplyActions: false,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
            ),
            endDrawer: Drawer(width: 300, child: _buildDrawer()),
            endDrawerEnableOpenDragGesture: false,
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
                              _toggleFullScreen(false);
                              _isFullScreen = false;
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
