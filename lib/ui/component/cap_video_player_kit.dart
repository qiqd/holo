import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/ui/component/cap_video_player_common_mixin.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class CapVideoPlayerKit extends StatefulWidget {
  final Player kitPlayer;
  final bool isloading;
  final String? title;
  final String? subTitle;
  final bool isFullScreen;
  final List<String> episodeList;
  final int currentEpisodeIndex;
  final Danmu? dammaku;
  final bool isTablet;
  final Function(bool)? onFullScreenChanged;
  final Function(String)? onError;
  final Function()? onNextTab;
  final Function(int index)? onEpisodeSelected;
  final Function()? onBackPressed;
  final Function(bool isPlaying)? onPlayOrPause;
  final Function(bool isShow)? onSettingTab;
  final Function(Duration position)? onPositionChanged;
  const CapVideoPlayerKit({
    super.key,
    required this.kitPlayer,
    required this.isloading,
    this.isTablet = false,
    this.isFullScreen = false,
    this.currentEpisodeIndex = 0,
    this.title,
    this.subTitle,
    this.episodeList = const [],
    this.dammaku,
    this.onFullScreenChanged,
    this.onNextTab,
    this.onError,
    this.onEpisodeSelected,
    this.onBackPressed,
    this.onPlayOrPause,
    this.onSettingTab,
    this.onPositionChanged,
  });

  @override
  State<CapVideoPlayerKit> createState() => _CapVideoPlayerKitState();
}

class _CapVideoPlayerKitState extends State<CapVideoPlayerKit>
    with CapVideoPlayerCommonMixin<CapVideoPlayerKit> {
  late final _kitController = VideoController(widget.kitPlayer);
  Timer? _keyboardTimer;
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    descendantsAreTraversable: false,
  );
  bool _showSetting = false;
  @override
  int get currentEpisodeIndex => widget.currentEpisodeIndex;

  @override
  bool get isFullScreen => widget.isFullScreen;

  @override
  void updateShowDragOffsetTimer() {
    super.videoTimer?.cancel();
    super.videoTimer = Timer(Duration(milliseconds: 500), () async {
      // _player.seekTo(Duration(seconds: videoPosition.toInt() + dragOffset));
      await widget.kitPlayer.seek(
        Duration(
          seconds: widget.kitPlayer.state.position.inSeconds + dragOffset,
        ),
      );
      widget.kitPlayer.play();
      setState(() {
        super.showDragOffset = false;
        super.dragOffset = 0;
      });
    });
  }

  /// 键盘事件处理
  void _handleKeyEvent(KeyEvent event) {
    if ((event is KeyDownEvent) &&
        !_showSetting &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.tab:
          break;

        case LogicalKeyboardKey.keyQ:
          setState(() {
            showEpisodeList = !showEpisodeList;
          });
          break;
        case LogicalKeyboardKey.space:
          widget.kitPlayer.playOrPause();
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
          widget.kitPlayer.seek(
            widget.kitPlayer.state.position + Duration(seconds: 5),
          );
          break;
        case LogicalKeyboardKey.arrowLeft:
          widget.kitPlayer.seek(
            widget.kitPlayer.state.position - Duration(seconds: 5),
          );
          break;
        case LogicalKeyboardKey.arrowUp:
          widget.kitPlayer.setVolume(
            (widget.kitPlayer.state.volume + 5).clamp(0, 100),
          );
          break;
        case LogicalKeyboardKey.arrowDown:
          widget.kitPlayer.setVolume(
            (widget.kitPlayer.state.volume - 5).clamp(0, 100),
          );
          break;
      }
    }
  }

  /// 初始化视频播放器监听器
  void _initListener() {
    _keyboardTimer?.cancel();
    _keyboardTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (super.showSetting) {
        return;
      }
      _focusNode.requestFocus();
    });
    var player = widget.kitPlayer;
    log('init volume:${player.state.volume}');
    setState(() {
      super.currentVolume = player.state.volume;
    });
    // 监听视频播放状态变化
    player.stream.volume.listen((event) {
      if (mounted) {
        setState(() {
          super.currentVolume = event;
        });
      }
    });
    player.stream.playing.listen((event) {
      if (mounted) {
        setState(() {
          super.isPlaying = event;
        });
      }
    });
    // 监听视频播放位置变化
    player.stream.position.listen((event) {
      if (mounted) {
        setState(() {
          super.position = event;
        });
      }
    });
    // 监听视频播放时长变化
    player.stream.duration.listen((event) {
      if (mounted) {
        setState(() {
          super.duration = event;
        });
      }
    });
    player.stream.buffer.listen((event) {
      if (mounted) {
        setState(() {
          super.bufferProgress = event.inSeconds.toDouble();
        });
      }
    });
    player.stream.rate.listen((event) {
      if (mounted) {
        setState(() {
          super.rate = event;
        });
      }
    });
    player.stream.buffering.listen((event) {
      if (mounted) {
        setState(() {
          super.isLoading = event || widget.isloading;
        });
      }
    });
  }

  @override
  void initState() {
    super.dammaku = widget.dammaku;
    super.initState();
    _initListener();
  }

  @override
  void didUpdateWidget(covariant CapVideoPlayerKit oldWidget) {
    if (oldWidget.currentEpisodeIndex != widget.currentEpisodeIndex) {
      super.danmakuItems.clear();
      super.fillDanmaku();
    }
    if (oldWidget.dammaku != widget.dammaku) {
      super.dammaku = widget.dammaku;
      super.danmakuItems.clear();
      super.fillDanmaku();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.showVideoControlsTimer();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: Theme.of(context).colorScheme.primary,
        ),
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            children: [
              //播放器层
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Video(
                    pauseUponEnteringBackgroundMode: false,
                    controller: _kitController,
                    controls: null,
                  ),
                ),
              ),

              // 弹幕层
              widget.dammaku != null ? buildDanmaku() : SizedBox.shrink(),
              // 加载中或缓冲中
              if (widget.kitPlayer.state.buffering || widget.isloading)
                LoadingOrShowMsg(msg: null),
              //亮度或者音量或者拖拽进度显示 can
              buildToast(),
              //视频控制层-中间
              SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: buildCenter(
                  playOrPause: () {
                    widget.kitPlayer.state.playing
                        ? widget.kitPlayer.pause()
                        : widget.kitPlayer.play();
                    setState(() {
                      super.isPlaying = widget.kitPlayer.state.playing;
                    });
                  },
                  onSettingTab: (bool isShow) =>
                      widget.onSettingTab?.call(isShow),
                  setVolume: (volume) => widget.kitPlayer.setVolume(volume),
                ),
              ),
              // 锁定
              buildLock(),
              // 时间
              buildTime(isFullScreen: widget.isFullScreen),
              //视频控制层-头部
              buildHeader(
                widget.title ?? context.tr("component.title"),
                subTitle: widget.subTitle,
                isFullScreen: widget.isFullScreen,
                onBackPressed: () {
                  widget.onBackPressed?.call();
                },
                onSettingTab: (isShow) {
                  widget.onSettingTab?.call(isShow);
                  setState(() {
                    showSetting = isShow;
                  });
                  showSetting
                      ? _focusNode.unfocus()
                      : _focusNode.requestFocus();
                },
              ),
              //视频控制层-底部
              buildBottom(
                setFullScreen: (isFullScreen) {
                  windowManager.setFullScreen(isFullScreen);
                },
                setRate: (rate) => widget.kitPlayer.setRate(rate),
                setVolume: (volume) => widget.kitPlayer.setVolume(volume),
                onFullScreenChanged: (isFullScreen) {
                  widget.onFullScreenChanged?.call(isFullScreen);
                },

                seekTo: (value) async {
                  await widget.kitPlayer.seek(value);
                  await widget.kitPlayer.play();
                },
                onPlayOrPause: () {
                  widget.kitPlayer.state.playing
                      ? widget.kitPlayer.pause()
                      : widget.kitPlayer.play();
                  setState(() {
                    super.isPlaying = widget.kitPlayer.state.playing;
                  });
                },
                onNextTab: () => widget.onNextTab?.call(),
              ),
              // 剧集列表
              buildEpisodeList(widget.episodeList, widget.onEpisodeSelected),
              // 弹幕设置
              buildDanmakuSetting(widget.isTablet, (isShow) {
                setState(() {
                  _showSetting = isShow;
                });
              }),
              //鼠标悬停显示视频控制条
              buildMouseHover(),
            ],
          ),
        ),
      ),
    );
  }
}
