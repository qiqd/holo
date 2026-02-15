import 'dart:async';
import 'dart:io';
import 'package:canvas_danmaku/danmaku_controller.dart';
import 'package:canvas_danmaku/danmaku_screen.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/util/local_store.dart';
import 'package:logger/logger.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:window_manager/window_manager.dart';
import 'package:holo/extension/safe_set_state.dart';

class CapVideoPlayerKit extends StatefulWidget {
  final ValueNotifier<VideoPlayerController?> playerNotifier;
  final bool isloading;
  final String? title;
  final String? subTitle;
  final bool isFullScreen;
  final int currentEpisodeIndex;
  final Danmu? dammaku;
  final bool isTablet;
  final bool enableAutoFocus;
  final DanmakuSetting danmakuSetting;
  final String centerMsg;
  final void Function(bool)? onFullScreenChanged;
  final void Function(String)? onError;
  final void Function()? onNextTab;
  final void Function()? onBackPressed;
  final void Function(bool isPlaying)? onPlayOrPause;
  final void Function()? onSettingTab;
  final void Function(Duration position)? onPositionChanged;
  final void Function()? onEpisodeTab;
  const CapVideoPlayerKit({
    super.key,
    required this.playerNotifier,
    required this.isloading,
    this.isTablet = false,
    this.isFullScreen = false,
    this.currentEpisodeIndex = 0,
    this.title,
    this.subTitle,
    this.danmakuSetting = const DanmakuSetting(),
    this.enableAutoFocus = true,
    this.dammaku,
    this.onFullScreenChanged,
    this.onNextTab,
    this.onError,
    this.onEpisodeTab,
    this.onBackPressed,
    this.centerMsg = '',
    this.onPlayOrPause,
    this.onSettingTab,
    this.onPositionChanged,
  });

  @override
  State<CapVideoPlayerKit> createState() => _CapVideoPlayerKitState();
}

class _CapVideoPlayerKitState extends State<CapVideoPlayerKit> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    descendantsAreTraversable: false,
  );
  final Logger _logger = Logger();
  late final ScreenBrightness _brightnessController;
  DanmakuController<double>? _danmuController;
  String msgText = '';
  bool showMsg = false;
  bool showVideoControls = true;
  bool isForward = true;
  int jumpMs = 0;
  int dragOffset = 0;
  bool isLock = false;
  Timer? volumeAndBrightnessToastTimer;
  Timer? videoControlsTimer;
  Timer? videoTimer;
  Timer? danmuTimer;
  double currentVolume = 0;
  double currentBrightness = 0;
  bool showDanmaku = true;
  bool showVolume = false;
  bool showBrightness = false;
  bool showDragOffset = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double bufferProgress = 0.0;
  bool isPlaying = false;
  double rate = 1.0;
  Danmu? dammaku;
  bool isLoading = false;
  Timer? danmakuSettingTimer;
  Timer? settingTimer;
  final List<DanmakuContentItem<double>> danmakuItems = [];

  /// 显示视频控制条定时器
  void showVideoControlsTimer() {
    // log("showVideoControlsTimer");
    videoControlsTimer?.cancel();
    videoControlsTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showVideoControls = false;
        });
      }
    });
  }

  /// 更新显示音量或亮度的定时器
  void updateShowVolumeOrBrightnessTimer() {
    volumeAndBrightnessToastTimer?.cancel();
    volumeAndBrightnessToastTimer = Timer(Duration(seconds: 5), () {
      setState(() {
        showBrightness = false;
        showVolume = false;
      });
    });
  }

  /// 改变亮度,仅在移动平台生效
  void changeBrightnessBy1Percent(SwipeDirection direction) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    if (isLock) {
      return;
    }
    showBrightness = true;
    showVolume = false;
    updateShowVolumeOrBrightnessTimer();
    final current = await _brightnessController.application;
    double newBrightness = current;
    if (direction == SwipeDirection.up) {
      newBrightness = current + 0.01;
    } else if (direction == SwipeDirection.down) {
      newBrightness = current - 0.01;
    }
    newBrightness = newBrightness.clamp(0.0, 1.0);
    await ScreenBrightness.instance.setApplicationScreenBrightness(
      newBrightness,
    );
    setState(() {
      showMsg = true;
      // msgText =     ' ${context.tr("component.cap_video_player.brightness")}: ${(newBrightness * 100).toStringAsFixed(0)}%';
      currentBrightness = newBrightness * 100;
    });
  }

  ///改变音量,仅在移动平台生效
  void changeVolumeBy1Percent(
    SwipeDirection direction,
    Function(double)? setVolume,
  ) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    if (isLock) {
      return;
    }
    showVolume = true;
    showBrightness = false;
    updateShowVolumeOrBrightnessTimer();
    final current = currentVolume;
    double newVolume = current;

    if (direction == SwipeDirection.up) {
      newVolume = current + 0.01;
    } else if (direction == SwipeDirection.down) {
      newVolume = current - 0.01;
    }
    newVolume = newVolume.clamp(0, 1);
    setVolume?.call(newVolume);
    setState(() {
      showMsg = true;
      currentVolume = newVolume;
    });
  }

  /// 处理视频进度改变事件
  void handleVideoProgressChange(SwipeDirection direction) {
    if (isLock) {
      return;
    }
    setState(() {
      showBrightness = false;
      showVolume = false;
      showDragOffset = true;
      if (direction == SwipeDirection.left) {
        dragOffset -= 1;
      } else if (direction == SwipeDirection.right) {
        dragOffset += 1;
      }
    });
    _updateShowDragOffsetTimer();
  }

  /// 填充弹幕
  void fillDanmaku() {
    if (_danmuController == null) return;
    var nomal =
        dammaku?.comments?.where((item) => item.type == 1).map((item) {
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
        dammaku?.comments?.where((item) => item.type == 4).map((item) {
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
        dammaku?.comments?.where((item) => item.type == 5).map((item) {
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
    danmakuItems.addAll(nomal);
    danmakuItems.addAll(bottom);
    danmakuItems.addAll(top);
  }

  /// 初始化弹幕定时器,用于填充弹幕
  void initTimerForDanmu({bool updateStateEverySecond = false}) {
    danmuTimer?.cancel();
    _danmuController?.updateOption(
      DanmakuOption(
        area: widget.danmakuSetting.area,
        opacity: widget.danmakuSetting.opacity,
        fontSize: widget.danmakuSetting.fontSize,
        hideBottom: widget.danmakuSetting.hideBottom,
        hideScroll: widget.danmakuSetting.hideScroll,
        hideTop: widget.danmakuSetting.hideTop,
        massiveMode: widget.danmakuSetting.massiveMode,
      ),
    );
    danmuTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (widget.enableAutoFocus &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        _focusNode.requestFocus();
      }
      if (updateStateEverySecond) {
        setState(() {});
      }
      if (_danmuController == null || !isPlaying || isLoading) {
        _danmuController?.pause();
        return;
      }
      if (danmakuItems.isEmpty) {
        fillDanmaku();
      }
      _danmuController?.resume();

      danmakuItems
          .where((item) {
            return item.extra?.toInt() ==
                (position.inSeconds + widget.danmakuSetting.danmakuOffset);
          })
          .forEach((item) {
            _danmuController?.addDanmaku(item);
          });
    });
  }

  /// 保存弹幕设置
  void saveDanmuSetting({DanmakuSetting? danmakuSetting}) {
    filterDanmakuItems();
    final appSetting = LocalStore.getAppSetting();
    appSetting.danmakuSetting = danmakuSetting ?? DanmakuSetting();
    settingTimer?.cancel();
    settingTimer = Timer(Duration(seconds: 5), () {
      LocalStore.saveAppSetting(appSetting);
    });
  }

  /// 过滤弹幕
  void filterDanmakuItems() {
    if (widget.danmakuSetting.filterWords.isEmpty) {
      return;
    }
    var filters = widget.danmakuSetting.filterWords.split(",");
    danmakuItems.removeWhere((item) {
      return filters.any((filter) => item.text.contains(filter.trim()) == true);
    });
  }

  ///显示键盘快捷键
  void showKeyboardShortcuts() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          title: Text('Keyboard Shortcuts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.play_arrow_rounded),
                title: Text('Play/Pause'),
                subtitle: Text('Space'),
              ),

              ListTile(
                leading: Icon(Icons.volume_up_rounded),
                title: Text('Volume Up'),
                subtitle: Text('Up Arrow'),
              ),
              ListTile(
                leading: Icon(Icons.volume_down_rounded),
                title: Text('Volume Down'),
                subtitle: Text('Down Arrow'),
              ),
              ListTile(
                leading: Icon(Icons.fast_forward_rounded),
                title: Text('Seek Forward'),
                subtitle: Text('Right Arrow'),
              ),
              ListTile(
                leading: Icon(Icons.fast_rewind_rounded),
                title: Text('Seek Backward'),
                subtitle: Text('Left Arrow'),
              ),
              ListTile(
                leading: Icon(CupertinoIcons.sidebar_right),
                title: Text('Show Episode List'),
                subtitle: Text('Q'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateShowDragOffsetTimer() {
    videoTimer?.cancel();
    videoTimer = Timer(Duration(milliseconds: 500), () async {
      // _player.seekTo(Duration(seconds: videoPosition.toInt() + dragOffset));
      final player = widget.playerNotifier.value;
      await player?.seekTo(
        Duration(seconds: player.value.position.inSeconds + dragOffset),
      );
      await player?.play();
      safeSetState(() {
        showDragOffset = false;
        dragOffset = 0;
      });
    });
  }

  /// 键盘事件处理
  void _handleKeyEvent(KeyEvent event) {
    if ((event is KeyDownEvent) &&
        widget.enableAutoFocus &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      var player = widget.playerNotifier.value;
      switch (event.logicalKey) {
        case LogicalKeyboardKey.tab:
          break;
        case LogicalKeyboardKey.keyQ:
          widget.onEpisodeTab?.call();
          break;
        case LogicalKeyboardKey.space:
          player?.value.isPlaying ?? false ? player?.pause() : player?.play();
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
          player?.seekTo(player.value.position + Duration(seconds: 5));
          break;
        case LogicalKeyboardKey.arrowLeft:
          player?.seekTo((player.value.position) - Duration(seconds: 5));
          break;
        case LogicalKeyboardKey.arrowUp:
          player?.setVolume((player.value.volume + 0.05).clamp(0, 1));
          break;
        case LogicalKeyboardKey.arrowDown:
          player?.setVolume((player.value.volume - 0.05).clamp(0, 1));
          break;
      }
    }
  }

  /// 初始化视频播放器监听器
  void _initListener() {
    widget.playerNotifier.addListener(() {
      var player = widget.playerNotifier.value;
      _logger.w('player is null? ${player == null}');
      if (player == null) {
        safeSetState(() {
          position = .zero;
          bufferProgress = 0.0;
          duration = Duration.zero;
        });
        return;
      }
      safeSetState(() {
        currentVolume = player.value.volume;
      });
      player.addListener(() {
        widget.onPositionChanged?.call(player.value.position);
        safeSetState(() {
          currentVolume = player.value.volume;
          isPlaying = player.value.isPlaying;
          position = player.value.position;
          duration = player.value.duration;
          rate = player.value.playbackSpeed;
          isLoading = player.value.isBuffering;
          bufferProgress = getBuffered();
        });
      });
    });
  }

  /// 获取缓存
  double getBuffered() {
    try {
      var player = widget.playerNotifier.value;
      final buffered = player?.value.buffered ?? [];
      if (buffered.isEmpty) return 0.0;
      Duration maxEnd = buffered.first.end;
      for (var range in buffered) {
        if (range.end > maxEnd) {
          maxEnd = range.end;
        }
      }
      var d = maxEnd.inSeconds.toDouble();
      return d >= (player?.value.duration.inSeconds.toDouble() ?? 0.0) ? 4 : d;
    } catch (e) {
      setState(() {
        msgText = e.toString();
      });
      return 0.0;
    }
  }

  @override
  void initState() {
    _initListener();

    initTimerForDanmu();
    dammaku = widget.dammaku;
    VolumeController.instance.showSystemUI = false;
    _brightnessController = ScreenBrightness.instance;
    super.initState();
  }

  @override
  void dispose() {
    _logger.w('dispose');
    widget.playerNotifier.value?.removeListener(() {});
    windowManager.setFullScreen(false);
    danmuTimer?.cancel();
    volumeAndBrightnessToastTimer?.cancel();
    videoTimer?.cancel();
    videoControlsTimer?.cancel();
    settingTimer?.cancel();
    super.dispose();
  }

  ///弹幕层
  Widget _buildDanmaku() {
    var danmakuSetting = widget.danmakuSetting;
    var option = DanmakuOption(
      hideTop: danmakuSetting.hideTop,
      hideBottom: danmakuSetting.hideBottom,
      hideScroll: danmakuSetting.hideScroll,
      massiveMode: danmakuSetting.massiveMode,
      area: danmakuSetting.area,
      fontSize: danmakuSetting.fontSize,
      opacity: danmakuSetting.opacity,
    );
    return (showDanmaku)
        ? DanmakuScreen<double>(
            createdController: (e) {
              _danmuController = e;
            },
            option: option,
          )
        : SizedBox.shrink();
  }

  ///亮度或者音量或者拖拽进度显示
  Widget _buildToast() {
    return AnimatedOpacity(
      curve: (showVolume || showBrightness || showDragOffset)
          ? Curves.decelerate
          : Curves.easeOutQuart,
      opacity: (showVolume || showBrightness || showDragOffset) ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: Alignment.center,
        child: showVolume
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentVolume > 0.66
                        ? Icons.volume_up_rounded
                        : currentVolume > 0.33
                        ? Icons.volume_down_rounded
                        : Icons.volume_mute_rounded,
                    color: Colors.white,
                  ),
                  Text(
                    "${(currentVolume * 100).toInt()}%",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : showBrightness
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentBrightness > 66
                        ? Icons.brightness_high_rounded
                        : currentBrightness > 33
                        ? Icons.brightness_medium_rounded
                        : Icons.brightness_low_rounded,
                    color: Colors.white,
                  ),
                  Text(
                    "${(currentBrightness).toInt()}%",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : showDragOffset
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
            : const SizedBox(),
      ),
    );
  }

  ///视频控制层-锁定
  Widget _buildLock() {
    return AnimatedOpacity(
      opacity: showVideoControls ? 1 : 0,
      duration: const Duration(milliseconds: 100),
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
    );
  }

  ///视频控制层-时间
  Widget _buildTime({bool isFullScreen = false}) {
    return AnimatedOpacity(
      opacity: showVideoControls && isFullScreen ? 1 : 0,
      duration: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            "${DateTime.now().hour}:${DateTime.now().minute}",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  ///视频控制层-头部
  Widget _buildHeader(
    String title, {
    String? subTitle,
    bool isFullScreen = false,
    Function()? onBackPressed,
    Function()? onSettingTab,
  }) {
    return AnimatedPositioned(
      key: const ValueKey('show_video_controls_top'),
      duration: const Duration(milliseconds: 300),
      top: showVideoControls && !isLock ? 0 : -73,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !showVideoControls,
        child: AnimatedOpacity(
          opacity: showVideoControls && !isLock ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              ),
            ),
            child: ListTile(
              horizontalTitleGap: 0,
              titleAlignment: ListTileTitleAlignment.center,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  showVideoControlsTimer();
                  onBackPressed?.call();
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
              subtitle: subTitle != null && subTitle.isNotEmpty
                  ? Text(subTitle, style: TextStyle(color: Colors.white))
                  : null,
              trailing: isFullScreen
                  ? SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: .end,
                        children: [
                          if (Platform.isLinux ||
                              Platform.isWindows ||
                              Platform.isMacOS)
                            IconButton(
                              tooltip: 'keyboard shortcuts',
                              onPressed: () {
                                showKeyboardShortcuts();
                              },
                              icon: const Icon(
                                Icons.help_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                          IconButton(
                            tooltip: 'Setting',
                            onPressed: () {
                              onSettingTab?.call();
                              showVideoControlsTimer();
                            },
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  ///视频控制层-中间
  Widget _buildCenter({Function()? playOrPause, Function(double)? setVolume}) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Expanded(
          child: SizedBox(
            child: SimpleGestureDetector(
              swipeConfig: SimpleSwipeConfig(
                horizontalThreshold: 5,
                swipeDetectionBehavior: SwipeDetectionBehavior.continuous,
              ),
              onTap: () => setState(() {
                showVideoControlsTimer();
                showVideoControls = !showVideoControls;
              }),
              onDoubleTap: () {
                playOrPause?.call();
                showVideoControlsTimer();
              },
              onHorizontalSwipe: (direction) =>
                  handleVideoProgressChange(direction),
              child: (Platform.isAndroid || Platform.isIOS)
                  ? Row(
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
                              changeBrightnessBy1Percent(direction);
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
                              changeVolumeBy1Percent(direction, setVolume);
                            },

                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.transparent,
                      height: double.infinity,
                      width: double.infinity,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// 视频控制层-底部
  Widget _buildBottom({
    Function(bool)? setFullScreen,
    Function(double)? setRate,
    Function(double)? setVolume,
    Function(bool)? onFullScreenChanged,
    Function(Duration)? seekTo,
    Function()? onPlayOrPause,
    Function? onNextTab,
  }) {
    return AnimatedPositioned(
      key: const ValueKey('show_video_controls_bottom'),
      duration: const Duration(milliseconds: 300),
      bottom: showVideoControls && !isLock ? 0 : -70,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        key: ValueKey('show_video_controls_bottom_opacity'),
        opacity: showVideoControls && !isLock ? 1.0 : 0.0,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
            ),
          ),
          child: Column(
            children: [
              // 进度条
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      onChanged: (_) {},
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 0,
                      ),
                      secondaryTrackValue: bufferProgress,
                      value: position.inSeconds.toDouble(),
                      max: duration.inSeconds.toDouble() + 4,
                      onChangeEnd: (value) {
                        showVideoControlsTimer();
                        setState(() {
                          seekTo?.call(Duration(seconds: value.toInt()));
                          onPlayOrPause?.call();
                        });
                      },
                    ),
                  ),
                ],
              ),
              // 播放按钮
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      showVideoControlsTimer();
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                      onPlayOrPause?.call();
                    },
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  // 下一集
                  IconButton(
                    onPressed: () {
                      showVideoControlsTimer();
                      onNextTab?.call();
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white,
                    ),
                  ),

                  //进度
                  Container(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: TextButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 0),
                        ),
                      ),
                      onPressed: null,
                      child: Text(
                        "${position.inMinutes}:${position.inSeconds.remainder(60)}/${duration.inMinutes}:${duration.inSeconds.remainder(60)}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  //弹幕开关按钮
                  IconButton(
                    tooltip: 'Danmaku Switch',
                    splashColor: Colors.transparent,
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        showDanmaku = !showDanmaku;
                      });
                      showVideoControlsTimer();
                    },
                    icon: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('弹', style: TextStyle(color: Colors.white)),
                        if (!showDanmaku)
                          Icon(Icons.block_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  //剧集列表按钮
                  if (widget.isFullScreen) ...[
                    IconButton(
                      tooltip: 'Episode List',
                      onPressed: () {
                        widget.onEpisodeTab?.call();
                        showVideoControlsTimer();
                      },
                      icon: Icon(
                        Icons.format_list_bulleted_rounded,
                        color: Colors.white,
                      ),
                    ),
                    PopupMenuButton(
                      tooltip: 'Playback Speed',
                      padding: .zero,
                      icon: Badge(
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                        label: Text(rate.toStringAsFixed(1)),
                      ),

                      onSelected: (value) {
                        setRate?.call(value);
                      },
                      itemBuilder: (context) {
                        var items = <PopupMenuItem<double>>[];
                        for (var i = 0.5; i <= 4.0; i += 0.5) {
                          items.add(
                            PopupMenuItem(value: i, child: Text(i.toString())),
                          );
                        }
                        return items.reversed.toList();
                      },
                    ),
                  ],
                  //音量调整,只在桌面端显示
                  if (Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux) ...[
                    IconButton(
                      tooltip: 'Volume',
                      onPressed: () {
                        setState(() {
                          currentVolume = 0;
                          setVolume?.call(currentVolume);
                        });
                      },
                      icon: Icon(
                        currentVolume > 0
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        min: 0,
                        max: 1,
                        padding: .symmetric(horizontal: 10),
                        value: currentVolume,
                        onChanged: (value) {
                          setVolume?.call(value);
                          setState(() {
                            currentVolume = value;
                          });
                        },
                      ),
                    ),
                  ],
                  Spacer(),

                  // 全屏按钮
                  IconButton(
                    onPressed: () async {
                      showVideoControlsTimer();
                      if (Platform.isWindows ||
                          Platform.isMacOS ||
                          Platform.isLinux) {
                        final full = await windowManager.isFullScreen();
                        await windowManager.setFullScreen(!full);
                      } else if (Platform.isAndroid || Platform.isIOS) {
                        widget.onFullScreenChanged?.call(!widget.isFullScreen);
                      }
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
    );
  }

  ///鼠标悬停显示视频控制条
  Widget _buildMouseHover() {
    return (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
        ? SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: MouseRegion(
              opaque: false,
              onHover: (event) => setState(() {
                showVideoControls = true;
                showVideoControlsTimer();
              }),
              onExit: (event) => setState(() {
                showVideoControls = false;
              }),
              child: const SizedBox.expand(),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  void didUpdateWidget(covariant CapVideoPlayerKit oldWidget) {
    if (oldWidget.currentEpisodeIndex != widget.currentEpisodeIndex) {
      danmakuItems.clear();
      fillDanmaku();
    }
    if (oldWidget.dammaku != widget.dammaku) {
      dammaku = widget.dammaku;
      danmakuItems.clear();
      fillDanmaku();
    }
    if (oldWidget.danmakuSetting != widget.danmakuSetting) {
      saveDanmuSetting(danmakuSetting: widget.danmakuSetting);
      danmakuSettingTimer?.cancel();
      danmakuSettingTimer = Timer(const Duration(milliseconds: 500), () {
        _danmuController?.updateOption(
          DanmakuOption(
            area: widget.danmakuSetting.area,
            opacity: widget.danmakuSetting.opacity,
            fontSize: widget.danmakuSetting.fontSize,
            hideBottom: widget.danmakuSetting.hideBottom,
            hideScroll: widget.danmakuSetting.hideScroll,
            hideTop: widget.danmakuSetting.hideTop,
            massiveMode: widget.danmakuSetting.massiveMode,
          ),
        );
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    showVideoControlsTimer();
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
          child: ValueListenableBuilder(
            valueListenable: widget.playerNotifier,
            builder: (context, player, child) {
              return Stack(
                children: [
                  //播放器层
                  if (player != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayer(player),
                      ),
                    ),
                  if (widget.centerMsg.isNotEmpty)
                    LoadingOrShowMsg(msg: widget.centerMsg),
                  // 弹幕层
                  widget.dammaku != null ? _buildDanmaku() : SizedBox.shrink(),
                  // 加载中或缓冲中
                  if ((player?.value.isBuffering ?? true) || widget.isloading)
                    LoadingOrShowMsg(msg: null),
                  //亮度或者音量或者拖拽进度显示 can
                  _buildToast(),
                  //视频控制层-中间
                  SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                    child: _buildCenter(
                      playOrPause: () {
                        isPlaying ? player?.pause() : player?.play();
                        safeSetState(() {
                          isPlaying = player?.value.isPlaying ?? false;
                        });
                      },
                      setVolume: (volume) async {
                        await player?.setVolume(volume);
                      },
                    ),
                  ),
                  // 锁定
                  _buildLock(),
                  // 时间
                  _buildTime(isFullScreen: widget.isFullScreen),
                  //视频控制层-头部
                  _buildHeader(
                    widget.title ?? context.tr("component.title"),
                    subTitle: widget.subTitle,
                    isFullScreen: widget.isFullScreen,
                    onBackPressed: () {
                      widget.onBackPressed?.call();
                    },
                    onSettingTab: () => widget.onSettingTab?.call(),
                  ),
                  //视频控制层-底部
                  _buildBottom(
                    setFullScreen: (isFullScreen) {
                      windowManager.setFullScreen(isFullScreen);
                    },
                    setRate: (rate) => player?.setPlaybackSpeed(rate),
                    setVolume: (volume) => player?.setVolume(volume),
                    onFullScreenChanged: (isFullScreen) {
                      widget.onFullScreenChanged?.call(isFullScreen);
                    },

                    seekTo: (value) async {
                      await player?.seekTo(value);
                      await player?.play();
                    },
                    onPlayOrPause: () {
                      (player?.value.isPlaying ?? false)
                          ? player?.pause()
                          : player?.play();
                      setState(() {
                        isPlaying = player?.value.isPlaying ?? false;
                      });
                    },
                    onNextTab: () => widget.onNextTab?.call(),
                  ),

                  //鼠标悬停显示视频控制条
                  _buildMouseHover(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
