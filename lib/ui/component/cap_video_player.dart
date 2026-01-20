import 'dart:async';
import 'dart:developer';

import 'package:canvas_danmaku/danmaku_controller.dart';
import 'package:canvas_danmaku/danmaku_screen.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';

import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:holo/entity/danmu.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/util/local_store.dart';
import 'package:lottie/lottie.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';

class CapVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isloading;
  final String? title;
  final String? subTitle;
  final bool isFullScreen;
  final List<String> episodeList;
  final int currentEpisodeIndex;
  final Danmu? dammaku;
  final Function(bool)? onFullScreenChanged;
  final Function(String)? onError;
  final Function()? onNextTab;
  final Function(int index)? onEpisodeSelected;
  final Function()? onBackPressed;
  final Function(bool isPlaying)? onPlayOrPause;
  final Function()? onSettingTab;
  const CapVideoPlayer({
    super.key,
    required this.controller,
    required this.isloading,
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
  });

  @override
  State<CapVideoPlayer> createState() => _CapVideoPlayerState();
}

class _CapVideoPlayerState extends State<CapVideoPlayer> {
  late final String title = widget.title ?? context.tr("component.title");
  late final VideoPlayerController _player = widget.controller;
  late final ScreenBrightness _brightnessController;
  DanmakuController<double>? _danmuController;
  double videoDuration = 0.0;
  double videoPosition = 0.0;
  double bufferedEnd = 0.0;
  double aspectRatio = 16 / 9;
  bool isPlaying = false;
  bool isBuffering = false;
  String msgText = '';
  bool showMsg = false;
  bool showVideoControls = true;
  bool showEpisodeList = false;
  bool isForward = true;
  int jumpMs = 0;
  int dragOffset = 0;
  bool isLock = false;
  bool _isShowDanmaku = true;
  bool _showSetting = false;
  bool _hideTopDanmaku = false;
  bool _hideBottomDanmaku = false;
  bool _hideScrollDanmaku = false;
  bool _massiveDanmakuMode = false;
  double _displayArea = 1.0;
  double _opacity = 1.0;
  double _danmakuFontsize = 16.0;
  //int _danmakuFontweight = 4;
  String _filter = "";
  int _danmakuOffset = 0;
  Timer? _timer;
  Timer? _videoControlsTimer;
  Timer? _videoTimer;
  Timer? _danmuTimer;
  double _currentVolume = 0;
  double _currentBrightness = 0;
  bool _showVolume = false;
  bool _showBrightness = false;
  bool _showDragOffset = false;
  final List<DanmakuContentItem<double>> _danmakuItems = [];
  void _showVideoControlsTimer() {
    // log("showVideoControlsTimer");
    _videoControlsTimer?.cancel();
    _videoControlsTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showVideoControls = false;
        });
      }
    });
  }

  void _addListener() {
    _player.addListener(() {
      if (_player.value.hasError) {
        log("error on video player: ${_player.value.errorDescription}");
        widget.onError?.call(_player.value.errorDescription ?? "");
      }
      if (mounted) {
        setState(() {
          videoPosition = _player.value.position.inSeconds.toDouble();
          bufferedEnd = getBufferedEnd();
          videoDuration = _player.value.duration.inSeconds.toDouble();
          isPlaying = _player.value.isPlaying;
          isBuffering = _player.value.isBuffering;
          aspectRatio = _player.value.aspectRatio;
        });
      }
    });
  }

  double getBufferedEnd() {
    final buffered = widget.controller.value.buffered;
    if (buffered.isEmpty) return 0.0;

    Duration maxEnd = buffered.first.end;
    for (var range in buffered) {
      if (range.end > maxEnd) {
        maxEnd = range.end;
      }
    }
    return maxEnd.inSeconds.toDouble();
  }

  void _updateShowVolumeOrBrightnessTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 5), () {
      setState(() {
        _showBrightness = false;
        _showVolume = false;
      });
    });
  }

  void _updateShowDragOffsetTimer() {
    _videoTimer?.cancel();
    _videoTimer = Timer(Duration(milliseconds: 500), () {
      _player.seekTo(Duration(seconds: videoPosition.toInt() + dragOffset));
      setState(() {
        _showDragOffset = false;
        dragOffset = 0;
      });
    });
  }

  void _changeBrightnessBy1Percent(SwipeDirection direction) async {
    if (isLock) {
      return;
    }
    _showBrightness = true;
    _showVolume = false;
    _updateShowVolumeOrBrightnessTimer();
    final current = await _brightnessController.application;
    double newBrightness = current;
    if (direction == SwipeDirection.up) {
      newBrightness = current + 0.01;
    } else if (direction == SwipeDirection.down) {
      newBrightness = current - 0.01;
    }
    log("set brightness to $newBrightness");
    newBrightness = newBrightness.clamp(0.0, 1.0);
    await ScreenBrightness.instance.setApplicationScreenBrightness(
      newBrightness,
    );
    setState(() {
      showMsg = true;
      // msgText =     ' ${context.tr("component.cap_video_player.brightness")}: ${(newBrightness * 100).toStringAsFixed(0)}%';
      _currentBrightness = newBrightness * 100;
    });
  }

  void _changeVolumeBy1Percent(SwipeDirection direction) async {
    if (isLock) {
      return;
    }
    _showVolume = true;
    _showBrightness = false;
    _updateShowVolumeOrBrightnessTimer();
    final current = widget.controller.value.volume;
    double newVolume = current;
    if (direction == SwipeDirection.up) {
      newVolume = current + 0.01;
    } else if (direction == SwipeDirection.down) {
      newVolume = current - 0.01;
    }
    log("set volume to $newVolume");
    newVolume = newVolume.clamp(0.0, 1.0);
    widget.controller.setVolume(newVolume);
    setState(() {
      showMsg = true;
      // msgText ='${context.tr("component.cap_video_player.volume")}: ${(newVolume * 100).toStringAsFixed(0)}%';
      _currentVolume = newVolume * 100;
    });
  }

  void _handleVideoProgressChange(SwipeDirection direction) {
    log("handleVideoProgressChange $direction");
    if (isLock) {
      return;
    }
    _updateShowDragOffsetTimer();
    setState(() {
      _showBrightness = false;
      _showVolume = false;
      _showDragOffset = true;
      if (direction == SwipeDirection.left) {
        dragOffset -= 1;
      } else if (direction == SwipeDirection.right) {
        dragOffset += 1;
      }
    });
  }

  void _fillDanmaku() {
    if (_danmuController == null) return;
    var danmu = widget.dammaku;
    var nomal =
        danmu?.comments?.where((item) => item.type == 1).map((item) {
          return DanmakuContentItem(
            item.text ?? "",
            type: DanmakuItemType.scroll,
            color: Color.fromRGBO(
              (item.color ?? 0xFFFFFFFF) >> 16 & 0xFF,
              (item.color ?? 0xFFFFFFFF) >> 8 & 0xFF,
              item.color ?? 0xFFFFFFFF & 0xFF,
              1,
            ),
            extra: item.time ?? 0,
          );
        }).toList() ??
        [];
    var bottom =
        danmu?.comments?.where((item) => item.type == 4).map((item) {
          return DanmakuContentItem(
            item.text ?? "",
            type: DanmakuItemType.bottom,
            color: Color.fromRGBO(
              (item.color ?? 0xFFFFFFFF) >> 16 & 0xFF,
              (item.color ?? 0xFFFFFFFF) >> 8 & 0xFF,
              item.color ?? 0xFFFFFFFF & 0xFF,
              1,
            ),
            extra: item.time ?? 0,
          );
        }).toList() ??
        [];
    var top =
        danmu?.comments?.where((item) => item.type == 5).map((item) {
          return DanmakuContentItem(
            item.text ?? "",
            type: DanmakuItemType.top,
            color: Color.fromRGBO(
              (item.color ?? 0xFFFFFFFF) >> 16 & 0xFF,
              (item.color ?? 0xFFFFFFFF) >> 8 & 0xFF,
              item.color ?? 0xFFFFFFFF & 0xFF,
              1,
            ),
            extra: item.time ?? 0,
          );
        }).toList() ??
        [];
    _danmakuItems.addAll(nomal);
    _danmakuItems.addAll(bottom);
    _danmakuItems.addAll(top);
  }

  void _initTimerForDanmu() {
    _danmuTimer?.cancel();
    _danmuTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_danmuController == null ||
          !_player.value.isPlaying ||
          widget.isloading) {
        _danmuController?.pause();
        return;
      }
      if (_danmakuItems.isEmpty) {
        _fillDanmaku();
      }
      _danmuController?.resume();
      var position = _player.value.position.inSeconds;
      _danmakuItems
          .where((item) {
            return item.extra?.toInt() == (position + _danmakuOffset);
          })
          .forEach((item) {
            _danmuController?.addDanmaku(item);
          });
    });
  }

  void _loadDanmuSetting() {
    var option = LocalStore.getDanmakuOption();
    if (option == null) return;
    final setting = option["option"] as DanmakuOption;

    _danmuController?.updateOption(setting);
    if (mounted) {
      setState(() {
        _hideTopDanmaku = setting.hideTop;
        _hideBottomDanmaku = setting.hideBottom;
        _hideScrollDanmaku = setting.hideScroll;
        _massiveDanmakuMode = setting.massiveMode;
        _displayArea = setting.area;
        _danmakuFontsize = setting.fontSize;
        // _danmakuFontweight = setting.fontWeight;
        _opacity = setting.opacity;
        _filter = option["filter"] as String;
      });
    }
  }

  void _saveDanmuSetting() {
    _filterDanmakuItems();
    LocalStore.saveDanmakuOption(
      _danmuController?.option ?? DanmakuOption(),
      filter: _filter,
    );
  }

  void _filterDanmakuItems() {
    if (_filter.isEmpty) {
      return;
    }
    var filters = _filter.split(",");
    _danmakuItems.removeWhere((item) {
      return filters.any((filter) => item.text.contains(filter.trim()) == true);
    });
  }

  @override
  void initState() {
    _addListener();
    _loadDanmuSetting();
    _initTimerForDanmu();
    VolumeController.instance.showSystemUI = false;
    _brightnessController = ScreenBrightness.instance;
    super.initState();
  }

  @override
  void dispose() {
    _danmuTimer?.cancel();
    _timer?.cancel();
    _videoTimer?.cancel();
    _videoControlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CapVideoPlayer oldWidget) {
    if (oldWidget.currentEpisodeIndex != widget.currentEpisodeIndex) {
      _danmakuItems.clear();
      _fillDanmaku();
    }
    if (oldWidget.dammaku != widget.dammaku) {
      _danmakuItems.clear();
      _fillDanmaku();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    // _showSetting = false;
    // showEpisodeList = false;
    _showVideoControlsTimer();
    _loadDanmuSetting();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Theme.of(context).colorScheme.primary,
      ),
      child: Stack(
        children: [
          //播放器层
          Center(
            child: AspectRatio(
              aspectRatio: _player.value.aspectRatio,
              child: VideoPlayer(_player),
            ),
          ),
          // 弹幕层
          if (widget.dammaku != null && _isShowDanmaku)
            DanmakuScreen<double>(
              createdController: (e) {
                _danmuController = e;
              },
              option: LocalStore.getDanmakuOption()?["option"] as DanmakuOption,
            ),
          // 加载中或缓冲中
          if (isBuffering || widget.isloading) LoadingOrShowMsg(msg: null),
          //亮度或者音量或者拖拽进度显示
          AnimatedOpacity(
            curve: (_showVolume || _showBrightness || _showDragOffset)
                ? Curves.decelerate
                : Curves.easeOutQuart,
            opacity: (_showVolume || _showBrightness || _showDragOffset)
                ? 1.0
                : 0.0,
            duration: Duration(milliseconds: 300),
            child: Align(
              alignment: Alignment.center,
              child: _showVolume
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentVolume > 66
                              ? Icons.volume_up_rounded
                              : _currentVolume > 33
                              ? Icons.volume_down_rounded
                              : Icons.volume_mute_rounded,
                          color: Colors.white,
                        ),
                        Text(
                          "${(_currentVolume).toInt()}%",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : _showBrightness
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentBrightness > 66
                              ? Icons.brightness_high_rounded
                              : _currentBrightness > 33
                              ? Icons.brightness_medium_rounded
                              : Icons.brightness_low_rounded,
                          color: Colors.white,
                        ),
                        Text(
                          "${(_currentBrightness).toInt()}%",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : _showDragOffset
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (dragOffset < 0)
                          Icon(Icons.fast_rewind_rounded, color: Colors.white),
                        Text(
                          "${(dragOffset.abs()).toInt()}s",
                          style: TextStyle(color: Colors.white),
                        ),
                        if (dragOffset > 0)
                          Icon(Icons.fast_forward_rounded, color: Colors.white),
                      ],
                    )
                  : SizedBox(),
            ),
          ),

          Column(
            children: [
              //视频控制层-头部
              IgnorePointer(
                ignoring: !showVideoControls,
                child: AnimatedOpacity(
                  opacity: showVideoControls && !isLock ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: ListTile(
                      horizontalTitleGap: 0,
                      titleAlignment: ListTileTitleAlignment.center,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          _showVideoControlsTimer();
                          _showSetting = false;
                          showEpisodeList = false;
                          widget.onBackPressed?.call();
                        },
                      ),
                      title: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      subtitle:
                          widget.subTitle != null && widget.subTitle!.isNotEmpty
                          ? Text(
                              widget.subTitle!,
                              style: TextStyle(color: Colors.white),
                            )
                          : null,
                      trailing: widget.isFullScreen
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _showSetting = !_showSetting;
                                });
                                _showVideoControlsTimer();
                              },
                              icon: Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              //视频控制层-中间
              Expanded(
                child: SizedBox(
                  child: SimpleGestureDetector(
                    swipeConfig: SimpleSwipeConfig(
                      horizontalThreshold: 5,
                      swipeDetectionBehavior: SwipeDetectionBehavior.continuous,
                    ),
                    onTap: () => setState(() {
                      setState(() {
                        showEpisodeList = false;
                        _showSetting = false;
                      });
                      _showVideoControlsTimer();
                      showVideoControls = !showVideoControls;
                    }),
                    onDoubleTap: () {
                      isPlaying ? _player.pause() : _player.play();
                      _showVideoControlsTimer();
                    },
                    onHorizontalSwipe: (direction) =>
                        _handleVideoProgressChange(direction),
                    child: Row(
                      children: [
                        //左边手势监听-亮度
                        Flexible(
                          child: SimpleGestureDetector(
                            swipeConfig: SimpleSwipeConfig(
                              verticalThreshold: 10,
                              horizontalThreshold: 9999,
                              swipeDetectionBehavior:
                                  SwipeDetectionBehavior.continuous,
                            ),
                            onVerticalSwipe: (direction) {
                              if (direction == SwipeDirection.left ||
                                  direction == SwipeDirection.right) {
                                return;
                              }
                              _changeBrightnessBy1Percent(direction);
                            },

                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        //右边手势监听-音量
                        Flexible(
                          child: SimpleGestureDetector(
                            swipeConfig: SimpleSwipeConfig(
                              verticalThreshold: 10,
                              horizontalThreshold: 9999,
                              swipeDetectionBehavior:
                                  SwipeDetectionBehavior.continuous,
                            ),
                            onVerticalSwipe: (direction) {
                              if (direction == SwipeDirection.left ||
                                  direction == SwipeDirection.right) {
                                return;
                              }
                              _changeVolumeBy1Percent(direction);
                            },

                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //视频控制层-底部
              IgnorePointer(
                ignoring: !showVideoControls,
                child: AnimatedOpacity(
                  opacity: showVideoControls && !isLock ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  duration: Duration(milliseconds: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // 进度条
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 0,
                                ),
                                secondaryTrackValue: getBufferedEnd(),
                                value: widget
                                    .controller
                                    .value
                                    .position
                                    .inSeconds
                                    .toDouble(),
                                max:
                                    widget.controller.value.duration.inSeconds
                                        .toDouble() +
                                    4,
                                onChangeEnd: (value) {
                                  _showVideoControlsTimer();
                                  setState(() {
                                    widget.controller.seekTo(
                                      Duration(seconds: value.toInt()),
                                    );
                                    widget.controller.play();
                                  });
                                },
                                onChanged: (value) {},
                              ),
                            ),
                          ],
                        ),
                        // 播放按钮
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                _showVideoControlsTimer();
                                if (widget.controller.value.isPlaying) {
                                  widget.controller.pause();
                                } else {
                                  widget.controller.play();
                                }
                                widget.onPlayOrPause?.call(
                                  widget.controller.value.isPlaying,
                                );
                                setState(() {});
                              },
                              icon: Icon(
                                widget.controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                            ),
                            // 下一集
                            IconButton(
                              onPressed: () {
                                _showVideoControlsTimer();
                                widget.onNextTab?.call();
                              },
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                              ),
                            ),

                            //进度
                            Container(
                              constraints: BoxConstraints(minWidth: 100),
                              child: TextButton(
                                style: ButtonStyle(
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(horizontal: 0),
                                  ),
                                ),
                                onPressed: null,
                                child: Text(
                                  "${widget.controller.value.position.inMinutes}:${widget.controller.value.position.inSeconds.remainder(60)}/${widget.controller.value.duration.inMinutes}:${widget.controller.value.duration.inSeconds.remainder(60)}",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            //弹幕
                            IconButton(
                              splashColor: Colors.transparent,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  _isShowDanmaku = !_isShowDanmaku;
                                });
                                _showVideoControlsTimer();
                              },
                              icon: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '弹',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  if (!_isShowDanmaku)
                                    Icon(
                                      Icons.block_rounded,
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                            //剧集列表
                            if (widget.isFullScreen) ...[
                              Badge(
                                backgroundColor: Colors.transparent,
                                textColor: Colors.white,
                                offset: Offset(0, 5),
                                label: Text(
                                  "${widget.currentEpisodeIndex + 1} ",
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showEpisodeList = !showEpisodeList;
                                    });
                                    _showVideoControlsTimer();
                                  },
                                  icon: Icon(
                                    Icons.format_list_bulleted_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14),
                              // 播放速度
                              Badge(
                                textColor: Colors.white,
                                offset: Offset(9, -7),
                                backgroundColor: Colors.transparent,
                                label: Text(
                                  widget.controller.value.playbackSpeed
                                      .toString(),
                                ),
                                child: PopupMenuButton(
                                  child: Icon(
                                    Icons.speed_rounded,
                                    color: Colors.white,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 2.0,
                                      child: Text('2.0x'),
                                      onTap: () => widget.controller
                                          .setPlaybackSpeed(2.0),
                                    ),
                                    PopupMenuItem(
                                      value: 1.5,
                                      child: Text('1.5x'),
                                      onTap: () => widget.controller
                                          .setPlaybackSpeed(1.5),
                                    ),
                                    PopupMenuItem(
                                      value: 1.25,
                                      child: Text('1.25x'),
                                      onTap: () => widget.controller
                                          .setPlaybackSpeed(1.25),
                                    ),
                                    PopupMenuItem(
                                      value: 1.0,
                                      child: Text('1.0x'),
                                      onTap: () => widget.controller
                                          .setPlaybackSpeed(1.0),
                                    ),
                                    PopupMenuItem(
                                      value: 0.75,
                                      child: Text('0.75x'),
                                      onTap: () => widget.controller
                                          .setPlaybackSpeed(0.75),
                                    ),
                                    PopupMenuItem(
                                      value: 0.5,
                                      child: Text('0.5x'),
                                      onTap: () => widget.controller
                                          .setPlaybackSpeed(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            Spacer(),
                            // 全屏
                            IconButton(
                              onPressed: () {
                                _showVideoControlsTimer();
                                _showSetting = false;
                                showEpisodeList = false;
                                widget.onFullScreenChanged?.call(
                                  !widget.isFullScreen,
                                );
                              },
                              icon: Icon(
                                widget.isFullScreen
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 锁定
          AnimatedOpacity(
            opacity: showVideoControls ? 1 : 0,
            duration: Duration(milliseconds: 100),
            child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      isLock = !isLock;
                    });
                  },
                  icon: Icon(
                    isLock ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // 时间
          AnimatedOpacity(
            opacity: showVideoControls && widget.isFullScreen ? 1 : 0,
            duration: Duration(milliseconds: 100),
            child: Padding(
              padding: EdgeInsets.only(top: 36),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "${DateTime.now().hour}:${DateTime.now().minute}",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          // 剧集列表
          AnimatedPositioned(
            top: 0,
            right: showEpisodeList && widget.isFullScreen ? 0 : -300,
            width: 300,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                key: PageStorageKey("player_episodes_list"),
                itemCount: widget.episodeList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    selected: index == widget.currentEpisodeIndex,
                    horizontalTitleGap: 0,
                    leading: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(widget.episodeList[index]),
                    trailing: widget.currentEpisodeIndex == index
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.primary,
                              BlendMode.srcATop,
                            ),
                            child: LottieBuilder.asset(
                              "lib/assert/lottie/playing2.json",
                              repeat: true,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                    onTap: () => widget.onEpisodeSelected?.call(index),
                  );
                },
              ),
            ),
          ),
          // 弹幕设置
          AnimatedPositioned(
            top: 0,
            right: _showSetting && widget.isFullScreen ? 0 : -300,
            width: 300,
            height: MediaQuery.of(context).size.height,
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 200),
            onEnd: () {
              if (_showSetting) return;
              _danmuController?.updateOption(
                DanmakuOption(
                  opacity: _opacity,
                  area: _displayArea,
                  fontSize: _danmakuFontsize,
                  hideTop: _hideTopDanmaku,
                  hideBottom: _hideBottomDanmaku,
                  hideScroll: _hideScrollDanmaku,
                  massiveMode: _massiveDanmakuMode,
                ),
              );
              _saveDanmuSetting();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          setState(() {
                            _filter = value;
                          });
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
                            child: Icon(
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
                          args: [_danmakuOffset.toString()],
                        ),
                      ),

                      leading: IconButton(
                        onPressed: () {
                          setState(() {
                            _danmakuOffset--;
                          });
                        },
                        icon: Icon(Icons.exposure_neg_1),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            _danmakuOffset++;
                          });
                        },
                        icon: Icon(Icons.exposure_plus_1),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.tr(
                          'component.cap_video_player.hide_top_danmaku',
                        ),
                      ),
                      trailing: Switch(
                        value: _hideTopDanmaku,
                        onChanged: (value) {
                          setState(() {
                            _hideTopDanmaku = value;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.tr(
                          'component.cap_video_player.hide_bottom_danmaku',
                        ),
                      ),
                      trailing: Switch(
                        value: _hideBottomDanmaku,
                        onChanged: (value) {
                          setState(() {
                            _hideBottomDanmaku = value;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.tr(
                          'component.cap_video_player.hide_scroll_danmaku',
                        ),
                      ),
                      trailing: Switch(
                        value: _hideScrollDanmaku,
                        onChanged: (value) {
                          setState(() {
                            _hideScrollDanmaku = value;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.tr(
                          'component.cap_video_player.massive_danmaku_mode',
                        ),
                      ),
                      subtitle: Text(
                        context.tr(
                          'component.cap_video_player.massive_danmaku_subtitle',
                        ),
                      ),
                      trailing: Switch(
                        value: _massiveDanmakuMode,
                        onChanged: (value) {
                          setState(() {
                            _massiveDanmakuMode = value;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.tr(
                          'component.cap_video_player.danmaku_opacity',
                        ),
                      ),
                      leading: null,
                      subtitle: Row(
                        children: [
                          Text('${(_opacity * 100).round()}%'),
                          Expanded(
                            child: Slider(
                              min: 0.1,
                              max: 1.0,
                              value: _opacity,
                              onChanged: (value) {
                                setState(() {
                                  _opacity = value;
                                });
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
                          Text('${(_displayArea * 100).round()}%'),
                          Expanded(
                            child: Slider(
                              min: 0.1,
                              max: 1.0,
                              value: _displayArea,
                              onChanged: (value) {
                                setState(() {
                                  _displayArea = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.tr(
                          'component.cap_video_player.danmaku_font_size',
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text('${(_danmakuFontsize).round()}'),
                          Expanded(
                            child: Slider(
                              min: 10.0,
                              max: 50.0,
                              value: _danmakuFontsize,
                              onChanged: (value) {
                                setState(() {
                                  _danmakuFontsize = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ListTile(
                    //   title: Text('字体粗细'),
                    //   subtitle: Row(
                    //     children: [
                    //       Text('${(_danmakuFontweight).round()}'),
                    //       Expanded(
                    //         child: Slider(
                    //           min: 2.0,
                    //           max: 10.0,
                    //           value: _danmakuFontweight,
                    //           onChanged: (value) {
                    //             setState(() {
                    //               _danmakuFontweight = value;
                    //             });
                    //           },
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
