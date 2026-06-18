import 'dart:async';
import 'dart:io';
import 'package:canvas_danmaku/danmaku_controller.dart';
import 'package:canvas_danmaku/danmaku_screen.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holo/assets/fonts/BF.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/entity/user_setting.dart';
import 'package:holo/ui/component/loading_msg.dart';
import 'package:holo/util/logger_util.dart';
import 'package:logger/logger.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:window_manager/window_manager.dart';
import 'package:holo/extension/safe_set_state_extension.dart';

class CapVideoPlayerKit extends StatefulWidget {
  final ValueNotifier<VideoPlayerController?> playerNotifier;
  final bool isLoading;
  final String? title;
  final String? subTitle;
  final bool isFullScreen;
  final int currentEpisodeIndex;
  final Danmu? dammaku;
  final bool isTablet;
  final bool enableAutoFocus;
  final DanmakuSetting danmakuSetting;
  final String centerMsg;
  final double? aspectRatio;
  final double safeInset;
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
    required this.isLoading,
    this.isTablet = false,
    this.isFullScreen = false,
    this.currentEpisodeIndex = 0,
    this.title,
    this.subTitle,
    this.danmakuSetting = const DanmakuSetting(),
    this.enableAutoFocus = true,
    this.aspectRatio,
    this.dammaku,
    this.safeInset = 40.0,
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
  final Logger _logger = LoggerUtil.logger;
  late final ScreenBrightness _brightnessController;
  DanmakuController<double>? _danmuController;
  bool _showVideoControls = true;
  int _dragOffset = 0;
  bool _isLock = false;
  Timer? _volumeAndBrightnessToastTimer;
  Timer? _videoControlsTimer;
  Timer? _videoTimer;
  Timer? _danmuTimer;
  double _currentVolume = 0.0;
  double _currentBrightness = 0.0;
  bool _showDanmaku = true;
  double _bufferProgress = 0.0;
  Danmu? _dammaku;
  Timer? _settingTimer;
  bool _isLandscape = false;
  int _toastShowMode = 0; //0:无,1:音量,2:亮度,3:进度
  final List<DanmakuContentItem<double>> _danmakuItems = [];
  Timer? _danmakuOptionTimer;

  /// 显示视频控制条定时器
  void _showVideoControlsTimer() {
    // log("showVideoControlsTimer");
    _videoControlsTimer?.cancel();
    _videoControlsTimer = Timer(Duration(seconds: 5), () {
      safeSetState(() {
        _showVideoControls = false;
      });
    });
  }

  /// 更新显示音量或亮度的定时器
  void _updateToastShowModeTimer() {
    _volumeAndBrightnessToastTimer?.cancel();
    _volumeAndBrightnessToastTimer = Timer(Duration(seconds: 1), () {
      safeSetState(() {
        _toastShowMode = 0;
      });
    });
  }

  /// 改变亮度,仅在移动平台生效
  void _changeBrightnessBy1Percent(SwipeDirection direction) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    if (_isLock) {
      return;
    }
    _toastShowMode = 2;
    _updateToastShowModeTimer();
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
    safeSetState(() {
      _currentBrightness = newBrightness * 100;
    });
  }

  ///改变音量,仅在移动平台生效
  Future<void> _changeVolumeBy1Percent(SwipeDirection direction) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    if (_isLock) {
      return;
    }
    double vol = await VolumeController.instance.getVolume();
    _toastShowMode = 1;
    _updateToastShowModeTimer();

    if (direction == SwipeDirection.up) {
      vol = vol + 0.01;
    } else if (direction == SwipeDirection.down) {
      vol = vol - 0.01;
    }
    vol = vol.clamp(0, 1);
    safeSetState(() {
      _currentVolume = vol;
    });
    await VolumeController.instance.setVolume(vol);
  }

  /// 处理视频进度改变事件
  void _handleVideoProgressChange(SwipeDirection direction) {
    if (_isLock) {
      return;
    }
    safeSetState(() {
      _toastShowMode = 3;
      if (direction == SwipeDirection.left) {
        _dragOffset -= 1;
      } else if (direction == SwipeDirection.right) {
        _dragOffset += 1;
      }
    });
    _updateShowDragOffsetTimer();
  }

  /// 填充弹幕
  void _fillDanmaku() {
    _filterDanmakuItems();
    if (_danmuController == null) return;
    var nomal =
        _dammaku?.comments?.where((item) => item.type == 1).map((item) {
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
        _dammaku?.comments?.where((item) => item.type == 4).map((item) {
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
        _dammaku?.comments?.where((item) => item.type == 5).map((item) {
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

  /// 初始化弹幕定时器,用于填充弹幕
  void _initTimerToDanmaku({bool updateStateEverySecond = false}) {
    _danmuTimer?.cancel();
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
    _danmuTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      //请求焦点,以便键盘事件生效
      if (widget.enableAutoFocus &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        _focusNode.requestFocus();
      }
      if (updateStateEverySecond) {
        safeSetState(() {});
      }
      if (_danmuController == null ||
          widget.isLoading ||
          !(widget.playerNotifier.value?.value.isPlaying ?? false) ||
          (widget.playerNotifier.value?.value.isBuffering ?? true)) {
        _danmuController?.pause();
        return;
      }
      if (_danmakuItems.isEmpty) {
        _fillDanmaku();
      }
      _danmuController?.resume();

      _danmakuItems
          .where((item) {
            return item.extra?.toInt() ==
                (widget.playerNotifier.value?.value.position.inSeconds ?? 0) +
                    widget.danmakuSetting.danmakuOffset;
          })
          .forEach((item) {
            _danmuController?.addDanmaku(item);
          });
    });
  }

  /// 过滤弹幕
  void _filterDanmakuItems() {
    if (widget.danmakuSetting.filterWords.isEmpty) {
      return;
    }
    var filters = widget.danmakuSetting.filterWords.split(",");
    _danmakuItems.removeWhere((item) {
      return filters.any((filter) => item.text.contains(filter.trim()) == true);
    });
  }

  ///显示键盘快捷键
  Future<void> _showKeyboardShortcuts() {
    return showDialog<void>(
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
                leading: Icon(Icons.list),
                title: Text('Show Episode List'),
                subtitle: Text('E'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateShowDragOffsetTimer() {
    _videoTimer?.cancel();
    _videoTimer = Timer(Duration(milliseconds: 500), () async {
      // _player.seekTo(Duration(seconds: videoPosition.toInt() + dragOffset));
      final player = widget.playerNotifier.value;
      await player?.seekTo(
        Duration(seconds: player.value.position.inSeconds + _dragOffset),
      );
      await player?.play();
      safeSetState(() {
        _dragOffset = 0;
        _toastShowMode = 0;
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
        case LogicalKeyboardKey.keyE:
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
          // player?.setVolume((player.value.volume + 0.05).clamp(0, 1));
          VolumeController.instance.setVolume(
            (_currentVolume + 0.05).clamp(0, 1),
          );
          break;
        case LogicalKeyboardKey.arrowDown:
          //player?.setVolume((player.value.volume - 0.05).clamp(0, 1));
          VolumeController.instance.setVolume(
            (_currentVolume - 0.05).clamp(0, 1),
          );
          break;
      }
    }
  }

  /// 初始化视频播放器监听器
  void _initListener() {
    widget.playerNotifier.addListener(() {
      var player = widget.playerNotifier.value;
      //  _logger.w('player is null? ${player == null}');
      if (player == null) {
        safeSetState(() {
          _bufferProgress = 0.0;
        });
        return;
      }

      player.removeListener(() {});

      player.addListener(() {
        widget.onPositionChanged?.call(player.value.position);
        safeSetState(() {
          _bufferProgress = _getBuffered();
        });
      });
    });
  }

  /// 获取缓存
  double _getBuffered() {
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
      return d >= (player?.value.duration.inSeconds.toDouble() ?? 0.0) ? 0 : d;
    } catch (e) {
      _logger.e(e);
      return 0.0;
    }
  }

  void _setPlaybackSpeed(double speed) {
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      var player = widget.playerNotifier.value;
      if (player?.value.playbackSpeed == speed) {
        timer.cancel();
      }
      await player?.setPlaybackSpeed(speed);
    });
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
    return (_showDanmaku)
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
      curve: _toastShowMode != 0 ? Curves.decelerate : Curves.easeOutQuart,
      opacity: _toastShowMode != 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          // width: ,
          padding: _toastShowMode == 0
              ? EdgeInsets.zero
              : const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                if (_toastShowMode == 1) ...[
                  Icon(
                    _currentVolume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 100,
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 0,
                        ),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                      ),
                      child: Slider(
                        value: _currentVolume,
                        onChanged: (_) {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
                if (_toastShowMode == 2) ...[
                  Icon(
                    _currentBrightness <= 20
                        ? Icons.brightness_low_rounded
                        : _currentBrightness <= 80
                        ? Icons.brightness_medium_rounded
                        : Icons.brightness_high_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 100,
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 0,
                        ),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                      ),
                      child: Slider(
                        value: _currentBrightness,
                        onChanged: (_) {},
                        min: 0,
                        max: 100,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
                if (_toastShowMode == 3) ...[
                  if (_dragOffset < 0)
                    Icon(Icons.fast_rewind_rounded, color: Colors.white),
                  Text(
                    "${(_dragOffset.abs()).toInt()}s",
                    style: TextStyle(color: Colors.white),
                  ),
                  if (_dragOffset > 0)
                    Icon(Icons.fast_forward_rounded, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///视频控制层-锁定
  Widget _buildLock() {
    return AnimatedOpacity(
      opacity: _showVideoControls ? 1 : 0,
      duration: const Duration(milliseconds: 100),
      child: Padding(
        padding: widget.isFullScreen
            ? EdgeInsets.only(left: widget.safeInset)
            : EdgeInsets.zero,
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            color: Colors.white,
            onPressed: () {
              safeSetState(() {
                _isLock = !_isLock;
              });
            },
            icon: Icon(_isLock ? Icons.lock_rounded : Icons.lock_open_rounded),
          ),
        ),
      ),
    );
  }

  ///视频控制层-时间
  Widget _buildTime() {
    return AnimatedOpacity(
      opacity: _showVideoControls && widget.isFullScreen ? 1 : 0,
      duration: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
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
  Widget _buildHeader() {
    return AnimatedPositioned(
      key: const ValueKey('show_video_controls_top'),
      duration: const Duration(milliseconds: 300),
      top: _showVideoControls && !_isLock ? 0 : -73,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showVideoControls && !_isLock ? 1.0 : 0.0,
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
          child: Padding(
            padding: widget.isFullScreen
                ? EdgeInsets.symmetric(horizontal: widget.safeInset)
                : EdgeInsets.zero,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              horizontalTitleGap: 6,
              titleAlignment: ListTileTitleAlignment.center,
              leading: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _showVideoControlsTimer();
                  widget.onBackPressed?.call();
                },
              ),
              title: Text(
                widget.title ?? context.tr("component.title"),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              subtitle: widget.subTitle != null && widget.subTitle!.isNotEmpty
                  ? Text(
                      widget.subTitle!,
                      style: TextStyle(color: Colors.white),
                    )
                  : null,
              trailing: widget.isFullScreen
                  ? SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: .end,
                        children: [
                          if (Platform.isLinux ||
                              Platform.isWindows ||
                              Platform.isMacOS)
                            IconButton(
                              color: Colors.white,
                              tooltip: 'Keyboard Shortcuts',
                              onPressed: () {
                                _showKeyboardShortcuts();
                              },
                              icon: const Icon(Icons.help_outline_rounded),
                            ),
                          IconButton(
                            color: Colors.white,
                            tooltip: 'Settings',
                            onPressed: () {
                              widget.onSettingTab?.call();
                              _showVideoControlsTimer();
                            },
                            icon: const Icon(Icons.settings_rounded),
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

  ///视频手势控制层-中间
  Widget _buildGesture({VideoPlayerController? player}) {
    return Padding(
      padding: widget.isFullScreen
          ? EdgeInsets.only(
              left: widget.safeInset,
              right: widget.safeInset,
              top: 40,
            )
          : EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              child: SimpleGestureDetector(
                swipeConfig: SimpleSwipeConfig(
                  horizontalThreshold: 5,
                  swipeDetectionBehavior: SwipeDetectionBehavior.continuous,
                ),
                onTap: () => safeSetState(() {
                  _showVideoControlsTimer();
                  _showVideoControls = !_showVideoControls;
                }),
                onDoubleTap: () {
                  (player?.value.isPlaying ?? false)
                      ? player?.pause()
                      : player?.play();
                  _showVideoControlsTimer();
                },
                onHorizontalSwipe: (direction) =>
                    _handleVideoProgressChange(direction),
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
      ),
    );
  }

  /// 视频控制层-底部
  Widget _buildBottom({VideoPlayerController? player}) {
    return AnimatedPositioned(
      key: const ValueKey('show_video_controls_bottom'),
      duration: const Duration(milliseconds: 300),
      bottom: _showVideoControls && !_isLock ? 0 : -70,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        key: ValueKey('show_video_controls_bottom_opacity'),
        opacity: _showVideoControls && !_isLock ? 1.0 : 0.0,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 100),
        child: Container(
          // padding: .symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
            ),
          ),
          child: Padding(
            padding: widget.isFullScreen
                ? EdgeInsets.symmetric(horizontal: widget.safeInset)
                : EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        secondaryTrackValue: _bufferProgress,
                        value: player?.value.position.inSeconds.toDouble() ?? 0,
                        max: player?.value.duration.inSeconds.toDouble() ?? 0,
                        onChangeEnd: (value) {
                          _showVideoControlsTimer();
                          player?.seekTo(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                  ],
                ),
                // 播放按钮
                Row(
                  children: [
                    IconButton(
                      color: Colors.white,
                      onPressed: () {
                        _showVideoControlsTimer();
                        (player?.value.isPlaying ?? false)
                            ? player?.pause()
                            : player?.play();
                      },
                      icon: Icon(
                        (player?.value.isPlaying ?? false)
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    // 下一集
                    IconButton(
                      color: Colors.white,
                      onPressed: () {
                        _showVideoControlsTimer();
                        widget.onNextTab?.call();
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                    ),

                    //进度
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 100),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 0),
                          ),
                        ),
                        onPressed: null,
                        child: Text(
                          "${(player?.value.position.inMinutes ?? 0).toString().padLeft(2, '0')}:${(player?.value.position.inSeconds.remainder(60) ?? 0).toString().padLeft(2, '0')}/${(player?.value.duration.inMinutes ?? 0).toString().padLeft(2, '0')}:${(player?.value.duration.inSeconds.remainder(60) ?? 0).toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    //播放速度按钮
                    PopupMenuButton(
                      tooltip: 'Playback Speed',
                      padding: .zero,
                      iconColor: Colors.white,
                      icon: Text(
                        "${player?.value.playbackSpeed ?? 1.0}x",
                        style: TextStyle(color: Colors.white),
                      ),
                      onSelected: (value) async {
                        _setPlaybackSpeed(value);
                      },
                      itemBuilder: (context) {
                        var items = <PopupMenuItem<double>>[];
                        for (var i = 0.5; i <= 4.0; i += 0.25) {
                          items.add(
                            PopupMenuItem(value: i, child: Text(i.toString())),
                          );
                        }
                        return items.reversed.toList();
                      },
                    ),

                    //弹幕开关按钮
                    IconButton(
                      tooltip: 'Danmaku Switch',
                      color: Colors.white,
                      onPressed: () {
                        safeSetState(() {
                          _showDanmaku = !_showDanmaku;
                        });
                        _showVideoControlsTimer();
                      },
                      icon: Icon(_showDanmaku ? BF.danmakuOn : BF.danmakuOff),
                    ),

                    if (widget.isFullScreen) ...[
                      //剧集列表按钮
                      IconButton(
                        color: Colors.white,
                        tooltip: 'Episode List',
                        onPressed: () {
                          widget.onEpisodeTab?.call();
                          _showVideoControlsTimer();
                        },
                        icon: Icon(Icons.format_list_bulleted_rounded),
                      ),
                    ],

                    //音量调整,只在桌面端显示
                    if (_isLandscape &&
                        (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux)) ...[
                      IconButton(
                        tooltip: 'Volume',
                        color: Colors.white,
                        onPressed: () {
                          widget.playerNotifier.value?.setVolume(0);
                          safeSetState(() {
                            _currentVolume = 0;
                          });
                        },
                        icon: Icon(
                          _currentVolume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Slider(
                          min: 0,
                          max: 1,

                          padding: .symmetric(horizontal: 10),
                          value: _currentVolume,
                          onChanged: (value) {
                            widget.playerNotifier.value?.setVolume(value);
                            safeSetState(() {
                              _currentVolume = value;
                            });
                          },
                        ),
                      ),
                    ],
                    Spacer(),

                    // 全屏按钮
                    IconButton(
                      color: Colors.white,
                      onPressed: () async {
                        _showVideoControlsTimer();
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux) {
                          final full = await windowManager.isFullScreen();
                          await windowManager.setFullScreen(!full);
                        } else if (Platform.isAndroid || Platform.isIOS) {
                          widget.onFullScreenChanged?.call(
                            !widget.isFullScreen,
                          );
                        }
                      },
                      icon: Icon(
                        widget.isFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              onHover: (event) => safeSetState(() {
                _showVideoControls = true;
                _showVideoControlsTimer();
              }),
              onExit: (event) => safeSetState(() {
                _showVideoControls = false;
              }),
              child: const SizedBox.expand(),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  void didUpdateWidget(covariant CapVideoPlayerKit oldWidget) {
    if (oldWidget.currentEpisodeIndex != widget.currentEpisodeIndex) {
      _danmakuItems.clear();
      _fillDanmaku();
    }
    if (oldWidget.dammaku != widget.dammaku) {
      _dammaku = widget.dammaku;
      _danmakuItems.clear();
      _fillDanmaku();
    }
    if (oldWidget.danmakuSetting != widget.danmakuSetting) {
      _filterDanmakuItems();
      _danmakuOptionTimer?.cancel();
      _danmakuOptionTimer = Timer(const Duration(milliseconds: 200), () {
        try {
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
        } catch (e) {
          _logger.e(e);
        }
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _initListener();
    _initTimerToDanmaku();
    _dammaku = widget.dammaku;
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.getVolume().then((v) {
      _currentVolume = v;
    });
    _brightnessController = ScreenBrightness.instance;
    super.initState();
  }

  @override
  void dispose() {
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    widget.playerNotifier.value?.removeListener(() {});
    _danmuTimer?.cancel();
    _danmakuOptionTimer?.cancel();
    _volumeAndBrightnessToastTimer?.cancel();
    _videoTimer?.cancel();
    _videoControlsTimer?.cancel();
    _settingTimer?.cancel();
    VolumeController.instance.removeListener();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _showVideoControlsTimer();
    safeSetState(() {
      _isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: ValueListenableBuilder(
        valueListenable: widget.playerNotifier,
        builder: (context, player, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              //播放器层
              if (player != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: widget.aspectRatio ?? player.value.aspectRatio,
                    //aspectRatio: 4 / 3,
                    child: VideoPlayer(player),
                  ),
                ),
              if (widget.centerMsg.isNotEmpty)
                LoadingOrShowMsg(msg: widget.centerMsg),
              // 弹幕层
              widget.dammaku != null ? _buildDanmaku() : SizedBox.shrink(),
              // 加载中或缓冲中
              if ((player?.value.isBuffering ?? false) || widget.isLoading)
                LoadingOrShowMsg(msg: null),
              //亮度或者音量或者拖拽进度显示 can
              _buildToast(),

              //视频控制层-中间
              SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: _buildGesture(player: player),
              ),
              // 锁定
              _buildLock(),
              // 时间
              _buildTime(),
              //视频控制层-头部
              _buildHeader(),
              //视频控制层-底部
              _buildBottom(player: player),

              //鼠标悬停显示视频控制条
              _buildMouseHover(),
            ],
          );
        },
      ),
    );
  }
}
