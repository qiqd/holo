// d:\flutterPrograms\Holo\mobile\mobile_holo\lib\ui\component\cap_video_player_common_mixin.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:canvas_danmaku/danmaku_controller.dart';
import 'package:canvas_danmaku/danmaku_screen.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:holo/entity/danmu.dart';
import 'package:holo/util/local_store.dart';
import 'package:lottie/lottie.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:volume_controller/volume_controller.dart';

/// 视频播放器公共逻辑 Mixin
/// 用于 CapVideoPlayerKit 和 CapVideoPlayer 的公共逻辑抽取
mixin CapVideoPlayerCommonMixin<T extends StatefulWidget> on State<T> {
  late final ScreenBrightness _brightnessController;
  DanmakuController<double>? _danmuController;
  String msgText = '';
  bool showMsg = false;
  bool showVideoControls = true;
  bool showEpisodeList = false;
  bool isForward = true;
  int jumpMs = 0;
  int dragOffset = 0;
  bool isLock = false;
  bool isShowDanmaku = true;
  bool showSetting = false;
  bool hideTopDanmaku = false;
  bool hideBottomDanmaku = false;
  bool hideScrollDanmaku = false;
  bool massiveDanmakuMode = false;
  double displayArea = 1.0;
  double opacity = 1.0;
  double danmakuFontsize = 16.0;
  final int danmakuFontweight = 4;
  String filter = "";
  int danmakuOffset = 0;
  Timer? timer;
  Timer? videoControlsTimer;
  Timer? videoTimer;
  Timer? danmuTimer;
  double currentVolume = 0;
  double currentBrightness = 0;
  bool showVolume = false;
  bool showBrightness = false;
  bool showDragOffset = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double bufferProgress = 0.0;
  bool isPlaying = true;
  double rate = 1.0;
  Danmu? dammaku;
  bool isLoading = false;

  /// 是否全屏,只在桌面平台生效
  bool _isFullScreen = false;
  final List<DanmakuContentItem<double>> danmakuItems = [];
  bool get isFullScreen;
  int get currentEpisodeIndex;

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
    timer?.cancel();
    timer = Timer(Duration(seconds: 5), () {
      setState(() {
        showBrightness = false;
        showVolume = false;
      });
    });
  }

  /// 更新显示拖动偏移量的定时器
  void updateShowDragOffsetTimer();

  /// 改变亮度,仅在移动平台生效
  @mustCallSuper
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
    log("set brightness to $newBrightness");
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
  @mustCallSuper
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
      newVolume = current + 1;
    } else if (direction == SwipeDirection.down) {
      newVolume = current - 1;
    }
    newVolume = newVolume.clamp(0, 100);
    setVolume?.call(newVolume);
    setState(() {
      showMsg = true;
      currentVolume = newVolume;
    });
  }

  /// 处理视频进度改变事件
  @mustCallSuper
  void handleVideoProgressChange(SwipeDirection direction) {
    log("handleVideoProgressChange $direction");
    if (isLock) {
      return;
    }
    updateShowDragOffsetTimer();
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
  }

  /// 填充弹幕
  @mustCallSuper
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
    danmuTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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
            return item.extra?.toInt() == (position.inSeconds + danmakuOffset);
          })
          .forEach((item) {
            _danmuController?.addDanmaku(item);
          });
    });
  }

  /// 加载弹幕设置
  void loadDanmuSetting() {
    var option = LocalStore.getDanmakuOption();
    if (option == null) return;
    final setting = option["option"] as DanmakuOption;

    _danmuController?.updateOption(setting);
    if (mounted) {
      setState(() {
        hideTopDanmaku = setting.hideTop;
        hideBottomDanmaku = setting.hideBottom;
        hideScrollDanmaku = setting.hideScroll;
        massiveDanmakuMode = setting.massiveMode;
        displayArea = setting.area;
        danmakuFontsize = setting.fontSize;
        // _danmakuFontweight = setting.fontWeight;
        opacity = setting.opacity;
        filter = option["filter"] as String;
      });
    }
  }

  /// 保存弹幕设置
  void saveDanmuSetting() {
    filterDanmakuItems();
    // log('hideTop:$_hideTopDanmaku');
    final option = DanmakuOption(
      hideTop: hideTopDanmaku,
      hideBottom: hideBottomDanmaku,
      hideScroll: hideScrollDanmaku,
      massiveMode: massiveDanmakuMode,
      area: displayArea,
      fontSize: danmakuFontsize,
      fontWeight: danmakuFontweight,
      opacity: opacity,
    );
    //log('filter:$_filter');
    LocalStore.saveDanmakuOption(option, filter: filter);
  }

  /// 过滤弹幕
  void filterDanmakuItems() {
    if (filter.isEmpty) {
      return;
    }
    var filters = filter.split(",");
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
                title: Text('Show Slidebar'),
                subtitle: Text('Q'),
              ),
            ],
          ),
        );
      },
    );
  }

  @mustCallSuper
  @override
  void initState() {
    loadDanmuSetting();
    initTimerForDanmu();
    VolumeController.instance.showSystemUI = false;
    _brightnessController = ScreenBrightness.instance;
    super.initState();
  }

  @mustCallSuper
  @override
  void dispose() {
    danmuTimer?.cancel();
    timer?.cancel();
    videoTimer?.cancel();
    videoControlsTimer?.cancel();
    super.dispose();
  }

  ///弹幕层
  Widget buildDanmaku() {
    return (isShowDanmaku)
        ? DanmakuScreen<double>(
            createdController: (e) {
              _danmuController = e;
            },
            option: LocalStore.getDanmakuOption()?["option"] as DanmakuOption,
          )
        : SizedBox.shrink();
  }

  ///亮度或者音量或者拖拽进度显示
  Widget buildToast() {
    return AnimatedOpacity(
      curve: (showVolume || showBrightness || showDragOffset)
          ? Curves.decelerate
          : Curves.easeOutQuart,
      opacity: (showVolume || showBrightness || showDragOffset) ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Align(
        alignment: Alignment.center,
        child: showVolume
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentVolume > 66
                        ? Icons.volume_up_rounded
                        : currentVolume > 33
                        ? Icons.volume_down_rounded
                        : Icons.volume_mute_rounded,
                    color: Colors.white,
                  ),
                  Text(
                    "${(currentVolume).toInt()}%",
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
            : SizedBox(),
      ),
    );
  }

  ///视频控制层-锁定
  Widget buildLock() {
    return AnimatedOpacity(
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
    );
  }

  ///视频控制层-时间
  Widget buildTime({bool isFullScreen = false}) {
    return AnimatedOpacity(
      opacity: showVideoControls && isFullScreen ? 1 : 0,
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
    );
  }

  ///视频控制层-头部
  Widget buildHeader(
    String title, {
    String? subTitle,
    bool isFullScreen = false,
    Function()? onBackPressed,
    Function(bool)? onSettingTab,
  }) {
    return AnimatedPositioned(
      key: ValueKey('show_video_controls_top'),
      duration: Duration(milliseconds: 300),
      top: showVideoControls && !isLock ? 0 : -73,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !showVideoControls,
        child: AnimatedOpacity(
          opacity: showVideoControls && !isLock ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
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
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  showVideoControlsTimer();
                  showSetting = false;
                  showEpisodeList = false;
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
                              icon: Icon(
                                Icons.help_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                          IconButton(
                            tooltip: 'Setting',
                            onPressed: () {
                              setState(() {
                                showSetting = !showSetting;
                                onSettingTab?.call(true);
                              });
                              showVideoControlsTimer();
                            },
                            icon: Icon(
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
  Widget buildCenter({
    Function()? playOrPause,
    Function(bool)? onSettingTab,
    Function(double)? setVolume,
  }) {
    return Column(
      children: [
        SizedBox(height: 40),
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
                  showSetting = false;
                  onSettingTab?.call(false);
                });
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

  /// 视频控制条-底部
  Widget buildBottom({
    Function(bool)? setFullScreen,
    Function(double)? setRate,
    Function(double)? setVolume,
    Function(bool)? onFullScreenChanged,
    Function(Duration)? seekTo,
    Function()? onPlayOrPause,
    Function? onNextTab,
  }) {
    return AnimatedPositioned(
      key: ValueKey('show_video_controls_bottom'),
      duration: Duration(milliseconds: 300),
      bottom: showVideoControls && !isLock ? 0 : -70,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        key: ValueKey('show_video_controls_bottom_opacity'),
        opacity: showVideoControls && !isLock ? 1.0 : 0.0,
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 100),
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
                    icon: Icon(Icons.skip_next_rounded, color: Colors.white),
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
                        isShowDanmaku = !isShowDanmaku;
                      });
                      showVideoControlsTimer();
                    },
                    icon: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('弹', style: TextStyle(color: Colors.white)),
                        if (!isShowDanmaku)
                          Icon(Icons.block_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  //剧集列表按钮
                  if (isFullScreen) ...[
                    Badge(
                      backgroundColor: Colors.transparent,
                      textColor: Colors.white,
                      offset:
                          (Platform.isWindows ||
                              Platform.isMacOS ||
                              Platform.isLinux)
                          ? null
                          : Offset(0, 5),
                      label: Text("${currentEpisodeIndex + 1} "),
                      child: IconButton(
                        tooltip: 'Episode List',
                        onPressed: () {
                          setState(() {
                            showEpisodeList = !showEpisodeList;
                          });
                          showVideoControlsTimer();
                        },
                        icon: Icon(
                          Icons.format_list_bulleted_rounded,
                          color: Colors.white,
                        ),
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
                  if ((Platform.isWindows ||
                          Platform.isMacOS ||
                          Platform.isLinux) &&
                      isFullScreen) ...[
                    IconButton(
                      tooltip: 'Volume',
                      onPressed: () {
                        setState(() {
                          log("btn- currentVolume:$currentVolume");
                          // currentVolume = 0;
                          // setVolume?.call(currentVolume);
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
                        max: 100,
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

                  // 全屏按钮(移动平台下,否则侧边栏)
                  IconButton(
                    onPressed: () {
                      showVideoControlsTimer();
                      showSetting = false;
                      showEpisodeList = false;
                      onFullScreenChanged?.call(!isFullScreen);
                    },
                    icon: (Platform.isAndroid || Platform.isIOS)
                        ? Icon(
                            isFullScreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: Colors.white,
                          )
                        : Icon(
                            CupertinoIcons.sidebar_right,
                            color: Colors.white,
                          ),
                  ),
                  if (Platform.isMacOS ||
                      Platform.isWindows ||
                      Platform.isLinux) ...[
                    IconButton(
                      tooltip: 'Fullscreen | Exit Fullscreen',
                      onPressed: () {
                        setState(() {
                          _isFullScreen = !_isFullScreen;
                        });
                        setFullScreen?.call(_isFullScreen);
                      },
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 剧集列表
  Widget buildEpisodeList(
    List<String> episodeList,
    Function(int)? onEpisodeSelected,
  ) {
    return AnimatedPositioned(
      top: 0,
      right: showEpisodeList && isFullScreen ? 0 : -300,
      width: 300,
      height: MediaQuery.of(context).size.height,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          key: PageStorageKey("player_episodes_list"),
          itemCount: episodeList.length,
          itemBuilder: (context, index) {
            return ListTile(
              selected: index == currentEpisodeIndex,
              horizontalTitleGap: 0,
              leading: Text(
                (index + 1).toString(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              title: Text(episodeList[index]),
              trailing: currentEpisodeIndex == index
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcATop,
                      ),
                      child: LottieBuilder.asset(
                        "lib/assets/lottie/playing2.json",
                        repeat: true,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              onTap: () => onEpisodeSelected?.call(index),
            );
          },
        ),
      ),
    );
  }

  ///  弹幕设置
  Widget buildDanmakuSetting(
    bool isTablet,
    Function(bool)? onShowSettingChanged,
  ) {
    return
    // 弹幕设置
    AnimatedPositioned(
      top: 0,
      right: showSetting && isFullScreen ? 0 : -300,
      width: 300,
      height: isTablet ? null : MediaQuery.of(context).size.height,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 200),
      onEnd: () {
        onShowSettingChanged?.call(showSetting);
        if (showSetting) return;
        _danmuController?.updateOption(
          DanmakuOption(
            opacity: opacity,
            area: displayArea,
            fontSize: danmakuFontsize,
            hideTop: hideTopDanmaku,
            hideBottom: hideBottomDanmaku,
            hideScroll: hideScrollDanmaku,
            massiveMode: massiveDanmakuMode,
          ),
        );
        saveDanmuSetting();
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
                child: TextFormField(
                  initialValue: filter,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    setState(() {
                      filter = value;
                    });
                    // log('input:$_filter');
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
                    args: [danmakuOffset.toString()],
                  ),
                ),

                leading: IconButton(
                  onPressed: () {
                    setState(() {
                      danmakuOffset--;
                    });
                  },
                  icon: Icon(Icons.exposure_neg_1),
                ),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      danmakuOffset++;
                    });
                  },
                  icon: Icon(Icons.exposure_plus_1),
                ),
              ),
              ListTile(
                title: Text(
                  context.tr('component.cap_video_player.hide_top_danmaku'),
                ),
                trailing: Switch(
                  value: hideTopDanmaku,
                  onChanged: (value) {
                    setState(() {
                      hideTopDanmaku = value;
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  context.tr('component.cap_video_player.hide_bottom_danmaku'),
                ),
                trailing: Switch(
                  value: hideBottomDanmaku,
                  onChanged: (value) {
                    setState(() {
                      hideBottomDanmaku = value;
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  context.tr('component.cap_video_player.hide_scroll_danmaku'),
                ),
                trailing: Switch(
                  value: hideScrollDanmaku,
                  onChanged: (value) {
                    setState(() {
                      hideScrollDanmaku = value;
                    });
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
                  value: massiveDanmakuMode,
                  onChanged: (value) {
                    setState(() {
                      massiveDanmakuMode = value;
                    });
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
                    Text('${(opacity * 100).round()}%'),
                    Expanded(
                      child: Slider(
                        min: 0.1,
                        max: 1.0,
                        value: opacity,
                        onChanged: (value) {
                          setState(() {
                            opacity = value;
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
                    Text('${(displayArea * 100).round()}%'),
                    Expanded(
                      child: Slider(
                        min: 0.1,
                        max: 1.0,
                        value: displayArea,
                        onChanged: (value) {
                          setState(() {
                            displayArea = value;
                          });
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
                    Text('${(danmakuFontsize).round()}'),
                    Expanded(
                      child: Slider(
                        min: 10.0,
                        max: 50.0,
                        value: danmakuFontsize,
                        onChanged: (value) {
                          setState(() {
                            danmakuFontsize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///鼠标悬停显示视频控制条
  Widget buildMouseHover() {
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
              child: SizedBox.expand(),
            ),
          )
        : SizedBox.shrink();
  }
}
