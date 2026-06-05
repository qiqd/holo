import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/web_dav.dart';
import 'package:holo/entity/anime_info.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/entity/episode_item.dart';
import 'package:holo/entity/log_var_episode.dart';
import 'package:holo/entity/media.dart' as holo_media;
import 'package:holo/entity/person.dart';
import 'package:holo/entity/related_work.dart';
import 'package:holo/entity/user_playback.dart';
import 'package:holo/entity/user_setting.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/component/cap_video_player_kit.dart';
import 'package:holo/ui/component/circle_avatar_with_text.dart';
import 'package:holo/ui/component/media_card.dart';
import 'package:holo/ui/component/person_detail.dart';
import 'package:holo/util/hive_util.dart';
import 'package:holo/util/jaro_winkler_similarity_util.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:holo/extension/safe_set_state_extension.dart';
import 'package:holo/util/logger_util.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pausable_timer/pausable_timer.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final String mediaId;
  final AnimeInfo subject;
  final SourceService source;
  final String nameCn;
  final bool isLove;
  final List<Person> person;
  final List<Person> character;
  final List<RelatedWork> relation;
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
  final Logger _logger = LoggerUtil.logger;
  late final AnimeInfo _subject = widget.subject;
  bool _isFullScreen = false;
  String _msg = "";
  int _episodeIndex = 0;
  int _lineIndex = 0;
  List<EpisodeInfo> _episode = [];
  holo_media.Detail? _detail;
  bool _isLoading = false;
  int _historyPosition = 0;
  String? _playUrl;
  bool _isActive = true;
  List<LogVarEpisode> _danmakuList = [];
  LogVarEpisode? _bestDanmakuSourceMatch;
  Danmu? _dammaku;
  bool _isDanmakuLoading = false;
  // bool _isTablet = false;
  bool _isEpisodeDrawerOpen = false;
  bool _isSettingDrawerOpen = false;
  bool _isInfoDrawerOpen = false;
  bool _enableAutoFocus = true;
  int _danmakuOffset = 0;
  late final String _nameCn = widget.nameCn;
  late final String _mediaId = widget.mediaId;
  late final SourceService _source = widget.source;
  final _playerNotifier = ValueNotifier<VideoPlayerController?>(null);
  Duration _position = Duration.zero;
  late final TabController _tabController = TabController(
    vsync: this,
    length: 2,
  );
  final SystemUiOverlayStyle _style = SystemUiOverlayStyle(
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.black,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
  );
  UserSetting _setting = HiveUtil.getUserSetting();
  UserPlayback? _userPlayback;
  String _danmakuKeyword = '';
  PausableTimer? _pausableTimer;

  Future<void> _fetchMediaEpisode() async {
    _isLoading = true;
    try {
      final res = await _source.fetchDetail(
        _mediaId,
        (e) => setState(() {
          _logger.e("fetchDetail1 error: $e");
          _msg = e.toString();
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
        _msg = e.toString();
      });
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _fetchViewInfo({
    int position = 0,
    bool loadDanmaku = true,
    void Function(String e)? onComplete,
  }) async {
    safeSetState(() {
      _msg = "";
      _isLoading = true;
    });
    try {
      if (_detail != null) {
        _lineIndex = _lineIndex.clamp(0, _detail!.lines!.length - 1);
        _episodeIndex = _episodeIndex.clamp(
          0,
          _detail!.lines![_lineIndex].episodes!.length - 1,
        );
        if (loadDanmaku) {
          _loadDanmaku(
            isFirstLoad: true,
            keyword: _danmakuKeyword.isNotEmpty ? _danmakuKeyword : _nameCn,
            onComplete: (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e),
                  showCloseIcon: true,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        }
        _playerNotifier.value?.pause();
        _playerNotifier.value?.dispose();
        _playerNotifier.value = null;
        final newUrl = await _source.fetchVideoUrl(
          _detail!.lines![_lineIndex].episodes![_episodeIndex],
          (e) => safeSetState(() {
            _logger.e("fetchVideoUrl error: $e");
            _msg = "player.playback_error".tr();
            _isLoading = false;
            onComplete?.call(_msg);
          }),
        );
        if (newUrl == null || newUrl.isEmpty) {
          safeSetState(() {
            _msg = "player.playback_error".tr();
            _isLoading = false;
            onComplete?.call(_msg);
          });
          return;
        }
        _playUrl = newUrl;
        final newController = VideoPlayerController.networkUrl(
          Uri.parse(newUrl),
        );
        await newController.initialize();

        _playerNotifier.value = newController;
        safeSetState(() {
          _msg = '';
        });
        _playerNotifier.value?.seekTo(Duration(seconds: position));
        _isActive
            ? _playerNotifier.value?.play()
            : _playerNotifier.value?.pause();
      }
    } catch (e) {
      _logger.e("fetchView error: $e");
      safeSetState(() {
        _msg = "player.playback_error".tr();
        onComplete?.call(_msg);
      });
    } finally {
      safeSetState(() {
        _isLoading = false;
      });
    }
  }

  void _onLineSelected(int index) {
    if (index == _lineIndex) {
      return;
    }
    setState(() {
      _lineIndex = index;
    });
    _fetchViewInfo(position: _position.inSeconds, loadDanmaku: false);
  }

  void _onEpisodeSelected(int index) {
    if (index >= _detail!.lines![_lineIndex].episodes!.length) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("player.episode_not_exist".tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      });
      return;
    }
    if (index == _episodeIndex) {
      return;
    }
    setState(() {
      _episodeIndex = index;
    });
    _fetchViewInfo();
  }

  Future<void> _loadPlaybackHistory() async {
    final history = HiveUtil.getUserPlaybacks(id: widget.subject.id);
    if (history.isNotEmpty) {
      safeSetState(() {
        _episodeIndex = history.first.episodeIndex;
        _lineIndex = history.first.lineIndex;
        _historyPosition = history.first.position;
        _userPlayback = history.first;
      });
    }
  }

  Future<void> _fetchEpisode() async {
    final res = await Api.bangumi.fetchEpisodeInfos(
      widget.subject.id,
      (e) => setState(() {
        _logger.e("fetchEpisode error: $e");
        _msg = e.toString();
      }),
    );
    if (mounted) {
      setState(() {
        _episode = res;
      });
    }
  }

  Future<void> _updatePlaybackHistory() async {
    if (_playUrl == null ||
        _position.inSeconds <= 0 ||
        _isLoading ||
        !(_playerNotifier.value?.value.isPlaying ?? false) ||
        _playerNotifier.value?.value.isBuffering == true) {
      return;
    }
    final newPlayback = _userPlayback == null
        ? UserPlayback(
            id: widget.subject.id,
            email: _setting.email,
            title: _nameCn,
            isSync: true,
            episodeIndex: _episodeIndex,
            lineIndex: _lineIndex,
            lastPlaybackAt: DateTime.now(),
            createdAt: DateTime.now(),
            position: _position.inSeconds,
            imgUrl: widget.subject.images.large ?? "",
            sourceName: _source.getName(),
          )
        : _userPlayback!.copyWith(
            position: _position.inSeconds,
            episodeIndex: _episodeIndex,
            lineIndex: _lineIndex,
            lastPlaybackAt: DateTime.now(),
            sourceName: _source.getName(),
          );

    var newPlaybackHistory = await HiveUtil.setUserPlaybacks([newPlayback]);
    await WebDAV.syncUserPlayback(newPlaybackHistory);
    //_logger.i('updatePlaybackHistory, newPlayback: $newPlayback');
  }

  Future<void> _updateUserSetting() async {
    await HiveUtil.setUserSetting(_setting);
    await WebDAV.syncUserSetting(_setting);
  }

  Future<void> _toggleFullScreen(bool isFullScreen) async {
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
      var data = await Api.logvar.fetchEpisodeFromLogVar(
        keyword ?? _subject.title,
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
        var temp = JaroWinklerSimilarityUtil.apply(
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
    var remainder = _episodeIndex.remainder(_episode.length);
    if (remainder >= (_bestDanmakuSourceMatch?.episodes?.length ?? 0)) {
      safeSetState(() {
        _isDanmakuLoading = false;
        onComplete?.call(
          "${_bestDanmakuSourceMatch?.animeTitle ?? ""} - ${"player.danmaku_not_exist".tr()}",
        );
      });
      return;
    }
    final danmu = await Api.logvar.fetchDanmakuSync(
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

  Future<void> _onDanmakuSourceChange(LogVarEpisode e) async {
    if (e.animeId == _bestDanmakuSourceMatch?.animeId) {
      return;
    }
    setState(() {
      _bestDanmakuSourceMatch = e;
    });
    return _loadDanmaku(
      isFirstLoad: false,
      keyword: _danmakuKeyword.isEmpty ? _nameCn : _danmakuKeyword,
      onComplete: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e),
            showCloseIcon: true,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Future<void> _showDanmakuBottomSheet() {
    setState(() {
      _enableAutoFocus = false;
    });
    //弹幕选择sheet
    return showModalBottomSheet<void>(
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
                      textInputAction: TextInputAction.search,
                      textAlign: TextAlign.center,
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
                        _danmakuKeyword = value;
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
                  child: (_danmakuList.isEmpty)
                      ? Center(child: Text('player.no_danmaku_sheet_text'.tr()))
                      : ListView.separated(
                          itemCount: _danmakuList.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1),
                          itemBuilder: (context, index) {
                            return ListTile(
                              selected:
                                  _bestDanmakuSourceMatch?.animeId ==
                                  _danmakuList[index].animeId,
                              title: Text(_danmakuList[index].animeTitle ?? ''),
                              subtitle: Text(
                                _danmakuList[index].animeTitle ?? '',
                              ),
                              onTap: () {
                                _onDanmakuSourceChange(_danmakuList[index]);
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

  Widget _buildPlayer({
    required bool isFullScreen,
    required bool isTablet,
    required void Function(bool isFullScreen) onFullScreenChanged,
    required void Function() onBackPressed,
  }) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: CapVideoPlayerKit(
          title: widget.nameCn,
          subTitle: _episode.isNotEmpty ? _episode[_episodeIndex].title : '',
          isLoading: _isLoading,
          centerMsg: _msg,
          playerNotifier: _playerNotifier,
          isFullScreen: isFullScreen,
          currentEpisodeIndex: _episodeIndex,
          dammaku: _dammaku,
          isTablet: isTablet,
          danmakuSetting: _setting.getDanmakuSetting(),
          enableAutoFocus: _enableAutoFocus,
          safeInset: _setting.playerSafeInset.toDouble(),
          onEpisodeTab: () {
            if (isTablet ||
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
            _msg = error.toString();
            _isLoading = false;
            _logger.e("player.error: $_msg");
          }),

          onNextTab: () {
            if (_isLoading ||
                _episodeIndex + 1 >
                    _detail!.lines![_lineIndex].episodes!.length - 1) {
              return;
            }
            setState(() {
              ++_episodeIndex;
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
    );
  }

  /// 简介
  Widget _buildSummary() {
    // var updateTo = checkUpdateAt(subject.airDate);
    return Material(
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          // 简介卡片
          SliverToBoxAdapter(
            child: MediaCard(
              id: "player_${_subject.id}",
              imageUrl: _subject.images.large!,
              title: _subject.title,
              genre: _subject.genres.join('/'),
              episode: _subject.episodes,
              rating: _subject.rating,
              ratingCount: _subject.ratingCount,
              height: 180,
              airDate: _subject.airDateTime != null
                  ? DateFormat.yMd().format(_subject.airDateTime!)
                  : null,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          // 数据源
          SliverToBoxAdapter(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              title: Text(
                "player.datasource".tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                _source.getName(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              leading: SizedBox(
                width: 100,
                child: Center(
                  child: Image.network(
                    width: double.infinity,
                    _source.getLogoUrl().contains('http')
                        ? _source.getLogoUrl()
                        : 'https://${_source.getLogoUrl()}',
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image_outlined);
                    },
                  ),
                ),
              ),
              trailing: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _danmakuList.isEmpty
                    ? SizedBox.shrink(
                        key: ValueKey('danmaku_source_statistics_empty'),
                      )
                    : Column(
                        key: ValueKey('danmaku_source_statistics'),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'player.danmaku_source_statistics',
                              args: [(_danmakuList.length).toString()],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            context.tr(
                              'player.danmaku_count_statistics',
                              args: [
                                (_dammaku?.comments?.length ?? 0).toString(),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (widget.character.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
          // 角色
          if (widget.character.isNotEmpty)
            _buildPersonGrid(
              title: "player.character".tr(),
              name2Image: {
                for (var e in widget.character)
                  e.name ?? '': e.images?.grid ?? "",
              },
              onTap: (index) =>
                  showPersonDetailBottomSheet(widget.character[index], context),
            ),
          if (widget.person.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
          // 人物
          /// TODO: 人物图片为空时，显示默认图片
          if (widget.person.isNotEmpty)
            _buildPersonGrid(
              title: "player.person".tr(),
              name2Image: {
                for (var e in widget.person) e.name ?? '': e.images?.grid ?? "",
              },
              onTap: (index) =>
                  showPersonDetailBottomSheet(widget.person[index], context),
            ),
        ],
      ),
    );
  }

  /// 剧集列表
  Widget _buildEpisode() {
    return _msg.isNotEmpty
        ? LoadingOrShowMsg(
            msg: _msg,
            onMsgTab: () {
              _fetchViewInfo();
            },
          )
        : GridView.builder(
            key: PageStorageKey("player_episodes"),
            padding: EdgeInsets.only(top: 6),
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
                selected: _episodeIndex == index,
                onTap: () {
                  if (_episodeIndex == index || _isLoading) {
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
                    if (_episodeIndex == index)
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcATop,
                        ),
                        child: LottieBuilder.asset(
                          "lib/assets/lottie/music_play.json",
                          repeat: true,
                          width: 24,
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

                          if (index == _lineIndex)
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcATop,
                              ),
                              child: LottieBuilder.asset(
                                "lib/assets/lottie/music_play.json",
                                repeat: true,
                                width: 20,
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TabBarView(
                controller: _tabController,
                children: [_buildSummary(), _buildEpisode()],
              ),
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
            selected: index == _episodeIndex,
            horizontalTitleGap: 0,
            leading: Text(
              (index + 1).toString(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            title: Text(eps[index].title),
            trailing: _episodeIndex == index
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcATop,
                    ),
                    child: LottieBuilder.asset(
                      "lib/assets/lottie/music_play.json",
                      repeat: true,
                      // fit: BoxFit.contain,
                      alignment: Alignment.center,
                      width: 24,
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
  Widget _buildSettingDrawer({
    required UserSetting setting,
    void Function(UserSetting setting)? onSettingChanged,
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
                  //  _logger.d('current offset:${setting.danmakuOffset}');
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
                  SizedBox(
                    width: 36,
                    child: Text('${(setting.opacity * 100).round()}%'),
                  ),
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
                  SizedBox(
                    width: 36,
                    child: Text('${(setting.area * 100).round()}%'),
                  ),
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
                  SizedBox(
                    width: 36,
                    child: Text('${(setting.fontSize).round()}'),
                  ),
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
            ListTile(
              title: Text(context.tr('component.cap_video_player.safe_inset')),
              subtitle: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('${(setting.playerSafeInset).round()}'),
                  ),
                  Expanded(
                    child: Slider(
                      min: 10.0,
                      max: 100.0,
                      value: setting.playerSafeInset.toDouble(),
                      onChanged: (value) {
                        onSettingChanged?.call(
                          setting.copyWith(playerSafeInset: value.toInt()),
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
  Widget _buildDrawer(bool isTablet) {
    if (_isEpisodeDrawerOpen) {
      return _buildEpisodeDrawer();
    } else if (_isSettingDrawerOpen) {
      return _buildSettingDrawer(
        setting: _setting,
        onSettingChanged: (s) => safeSetState(() {
          _setting = s;
        }),
      );
    } else if (_isInfoDrawerOpen && isTablet) {
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
        margin: .zero,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shadowColor: Colors.transparent,
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
      //_updatePlaybackHistory();
      _pausableTimer?.pause();
    }
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isActive = true;
      });
      _pausableTimer?.reset();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.setTitle(widget.nameCn);
    }
    _loadPlaybackHistory();
    _fetchEpisode();
    //_isTablet = Device.get().isTablet;
    WidgetsBinding.instance.addObserver(this);
    _fetchMediaEpisode().then(
      (value) => _fetchViewInfo(position: _historyPosition),
    );
    // 设置播放器页面的状态栏样式（深色模式）
    // SystemChrome.setSystemUIOverlayStyle(
    //   SystemUiOverlayStyle(
    //     statusBarIconBrightness: Brightness.light, // 浅色图标
    //     statusBarBrightness: Brightness.dark, // 深色状态栏
    //   ),
    // );
    _pausableTimer = PausableTimer.periodic(
      Duration(seconds: _setting.dataSyncInterval),
      () => _updatePlaybackHistory(),
    );
    _pausableTimer?.start();
    super.initState();
  }

  @override
  void dispose() {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      PackageInfo.fromPlatform().then((info) {
        windowManager.setTitle(info.appName);
      });
    }
    _updatePlaybackHistory();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _tabController.dispose();
    _playerNotifier.value?.dispose();
    _pausableTimer?.cancel();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    _logger.d("didRequestAppExit");
    return _updatePlaybackHistory().then((_) => super.didRequestAppExit());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var isTablet = min(constraints.maxWidth, constraints.maxHeight) >= 600;
        if (isTablet) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        }
        return isTablet
            // PC端，包含平板
            ? Scaffold(
                key: _globalScaffoldKey,
                resizeToAvoidBottomInset: false,
                onEndDrawerChanged: (isOpened) {
                  setState(() {
                    _enableAutoFocus = !isOpened;
                  });
                  if (!isOpened && _isSettingDrawerOpen) {
                    _updateUserSetting();
                  }
                },
                endDrawerEnableOpenDragGesture: false,
                endDrawer: Drawer(width: 400, child: _buildDrawer(isTablet)),
                body: SafeArea(
                  child: SizedBox.expand(
                    child: Row(
                      children: [
                        _buildPlayer(
                          isFullScreen: true,
                          isTablet: isTablet,
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
                  // foregroundColor: Colors.white,
                  automaticallyImplyActions: false,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 0,
                  systemOverlayStyle:
                      Theme.of(context).brightness == Brightness.dark
                      ? _style.copyWith(
                          systemNavigationBarIconBrightness: Brightness.light,
                        )
                      : _style.copyWith(
                          systemNavigationBarIconBrightness: Brightness.dark,
                        ),
                ),
                endDrawer: Drawer(width: 300, child: _buildDrawer(isTablet)),
                onEndDrawerChanged: (isOpened) {
                  if (!isOpened && _isSettingDrawerOpen) {
                    _updateUserSetting();
                  }
                },
                endDrawerEnableOpenDragGesture: false,
                body: Center(
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
                        Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: _buildPlayer(
                            isFullScreen: _isFullScreen,
                            isTablet: isTablet,
                            onFullScreenChanged: (isFullScreen) {
                              setState(() {
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
                        ),
                        //剧集列表
                        if (!_isFullScreen)
                          Flexible(flex: 2, child: _buildInfo()),
                      ],
                    ),
                  ),
                ),
              );
      },
    );
  }
}
