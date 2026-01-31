import 'dart:async';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/ui/component/cap_video_player_common_mixin.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

class CapVideoPlayer extends StatefulWidget {
  final VideoPlayerController player;
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
  final Function()? onPlayOrPause;
  final Function(bool isShow)? onSettingTab;
  final Function(Duration position)? onPositionChanged;
  const CapVideoPlayer({
    super.key,
    required this.player,
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
  State<CapVideoPlayer> createState() => _CapVideoPlayerKitState();
}

class _CapVideoPlayerKitState extends State<CapVideoPlayer>
    with CapVideoPlayerCommonMixin<CapVideoPlayer> {
  /// 初始化视频播放器监听器
  void _initListener() {
    var player = widget.player;
    super.currentVolume = player.value.volume;
    widget.player.addListener(() {
      if (player.value.hasError) {
        log("error on video player: ${player.value.errorDescription}");
        widget.onError?.call(player.value.errorDescription ?? "");
      }
      setState(() {
        super.isPlaying = player.value.isPlaying;
        super.position = player.value.position;
        super.duration = player.value.duration;
        super.bufferProgress = getBuffered();
        super.rate = player.value.playbackSpeed;
        super.isLoading = player.value.isBuffering || widget.isloading;
      });
    });
  }

  @override
  int get currentEpisodeIndex => widget.currentEpisodeIndex;

  @override
  bool get isFullScreen => widget.isFullScreen;

  /// 更新显示拖动偏移量的定时器
  @override
  void updateShowDragOffsetTimer() {
    super.videoTimer?.cancel();
    super.videoTimer = Timer(Duration(milliseconds: 500), () async {
      // _player.seekTo(Duration(seconds: videoPosition.toInt() + dragOffset));
      await widget.player.seekTo(
        Duration(seconds: widget.player.value.position.inSeconds + dragOffset),
      );
      widget.player.play();
      setState(() {
        super.showDragOffset = false;
        super.dragOffset = 0;
      });
    });
  }

  /// 获取缓存
  double getBuffered() {
    try {
      final buffered = widget.player.value.buffered;
      if (buffered.isEmpty) return 0.0;

      Duration maxEnd = buffered.first.end;
      for (var range in buffered) {
        if (range.end > maxEnd) {
          maxEnd = range.end;
        }
      }
      var d = maxEnd.inSeconds.toDouble();

      return d >= widget.player.value.duration.inSeconds.toDouble() ? 4 : d;
    } catch (e) {
      setState(() {
        msgText = e.toString();
      });
      return 0.0;
    }
  }

  @override
  void initState() {
    super.dammaku = widget.dammaku;
    super.initState();
    _initListener();
  }

  @override
  void didUpdateWidget(covariant CapVideoPlayer oldWidget) {
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
        child: Stack(
          children: [
            //播放器层
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: VideoPlayer(widget.player),
              ),
            ),

            // 弹幕层
            widget.dammaku != null ? buildDanmaku() : SizedBox.shrink(),
            // 加载中或缓冲中
            if (widget.player.value.isBuffering || widget.isloading)
              LoadingOrShowMsg(msg: null),
            //亮度或者音量或者拖拽进度显示 can
            buildToast(),
            //视频控制层-中间
            buildCenter(
              playOrPause: () {
                widget.player.value.isPlaying
                    ? widget.player.pause()
                    : widget.player.play();
                setState(() {
                  super.isPlaying = widget.player.value.isPlaying;
                });
              },
              onSettingTab: (bool isShow) => widget.onSettingTab?.call(isShow),
              setVolume: (volume) => widget.player.setVolume(volume),
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
              },
            ),
            //视频控制层-底部
            buildBottom(
              setFullScreen: (isFullScreen) =>
                  windowManager.setFullScreen(isFullScreen),
              setRate: (rate) => widget.player.setPlaybackSpeed(rate),
              setVolume: (volume) => widget.player.setVolume(volume),
              onFullScreenChanged: (isFullScreen) =>
                  widget.onFullScreenChanged?.call(isFullScreen),
              seekTo: (value) async {
                await widget.player.seekTo(value);
                await widget.player.play();
              },
              onPlayOrPause: () {
                widget.player.value.isPlaying
                    ? widget.player.pause()
                    : widget.player.play();
                setState(() {
                  super.isPlaying = widget.player.value.isPlaying;
                });
              },
              onNextTab: () => widget.onNextTab?.call(),
            ),
            // 剧集列表
            buildEpisodeList(widget.episodeList, widget.onEpisodeSelected),
            // 弹幕设置
            buildDanmakuSetting(widget.isTablet, (_) {}),
            //鼠标悬停显示视频控制条
            buildMouseHover(),
          ],
        ),
      ),
    );
  }
}
