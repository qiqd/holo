import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_holo/ui/component/loading_msg.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';

class CapVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isloading;
  final String? title;
  final bool isFullScreen;
  final Function(bool)? onFullScreenChanged;
  final Function(String)? onError;
  final Function()? onNextTab;
  const CapVideoPlayer({
    super.key,
    required this.controller,
    required this.isloading,
    this.isFullScreen = false,
    this.title = "暂无标题",
    this.onFullScreenChanged,
    this.onNextTab,
    this.onError,
  });

  @override
  State<CapVideoPlayer> createState() => _CapVideoPlayerState();
}

class _CapVideoPlayerState extends State<CapVideoPlayer> {
  late bool _isFullScreen = widget.isFullScreen;
  late final String title = widget.title ?? "暂无标题";
  late final VideoPlayerController player = widget.controller;

  late final ScreenBrightness brightnessController;
  double videoDuration = 0.0;
  double videoPosition = 0.0;
  double bufferedEnd = 0.0;
  double aspectRatio = 16 / 9;
  bool isPlaying = false;
  bool isBuffering = false;
  String msgText = '';
  bool showMsg = false;
  bool showVideoControls = true;
  bool isForward = true;
  int jumpMs = 0;
  int dragOffset = 0;
  bool isLock = false;
  Timer? _timer;
  Timer? _videoControlsTimer;
  Timer? _videoTimer;
  void _showVideoControlsTimer() {
    log("showVideoControlsTimer");
    _videoControlsTimer?.cancel();
    _videoControlsTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showVideoControls = false;
        });
      }
    });
  }

  void _toggleFullScreen() async {
    if (_isFullScreen) {
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
    widget.onFullScreenChanged?.call(_isFullScreen);
  }

  void _addListener() {
    player.addListener(() {
      if (player.value.hasError) {
        log("播放器发生错误: ${player.value.errorDescription}");
        widget.onError?.call(player.value.errorDescription ?? "");
      }
      if (mounted) {
        setState(() {
          videoPosition = player.value.position.inSeconds.toDouble();
          bufferedEnd = getBufferedEnd();
          videoDuration = player.value.duration.inSeconds.toDouble();
          isPlaying = player.value.isPlaying;
          isBuffering = player.value.isBuffering;
          aspectRatio = player.value.aspectRatio;
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

  void _startOrRestartTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 5), () {
      setState(() {
        showMsg = false;
      });
    });
  }

  void _startOrRestartVideoTimer() {
    setState(() {
      showMsg = true;
    });
    _videoTimer?.cancel();
    _videoTimer = Timer(Duration(milliseconds: 500), () {
      player.seekTo(Duration(seconds: videoPosition.toInt() + dragOffset));
      setState(() {
        dragOffset = 0;
        showMsg = false;
      });
    });
  }

  void decreaseBrightnessBy1Percent(SwipeDirection direction) async {
    if (isLock) {
      return;
    }
    showMsg = true;
    _startOrRestartTimer();
    final current = await brightnessController.application;
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
      msgText = '亮度: ${(newBrightness * 100).toStringAsFixed(0)}%';
    });
  }

  void decreaseVolumeBy1Percent(SwipeDirection direction) async {
    if (isLock) {
      return;
    }
    showMsg = true;
    _startOrRestartTimer();
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
      msgText = '音量: ${(newVolume * 100).toStringAsFixed(0)}%';
    });
  }

  void handleVideoProgressChange(SwipeDirection direction) {
    log("handleVideoProgressChange $direction");
    if (isLock) {
      return;
    }
    _startOrRestartVideoTimer();

    if (direction == SwipeDirection.left) {
      dragOffset -= 1;
    } else if (direction == SwipeDirection.right) {
      dragOffset += 1;
    }

    setState(() {
      msgText = dragOffset < 0 ? "后退${dragOffset.abs()}秒" : "前进$dragOffset秒";
    });
  }

  // void _setPlaybackSpeed(double speed) {
  //   player.setPlaybackSpeed(speed);
  // }

  @override
  void initState() {
    _addListener();
    VolumeController.instance.showSystemUI = false;
    brightnessController = ScreenBrightness.instance;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _showVideoControlsTimer();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (_isFullScreen) {
          setState(() {
            _isFullScreen = false;
          });
          _toggleFullScreen();
        } else if (!didPop) {
          context.pop();
        }
      },
      child: Stack(
        children: [
          //播放器
          !isBuffering && !widget.isloading
              ? VideoPlayer(player)
              : LoadingOrShowMsg(msg: msgText, backgroundColor: Colors.black),
          AnimatedOpacity(
            curve: showMsg ? Curves.decelerate : Curves.easeOutQuart,
            opacity: showMsg ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: Align(
              alignment: Alignment.center,
              child: Text(msgText, style: TextStyle(color: Colors.white)),
            ),
          ),

          Column(
            children: [
              IgnorePointer(
                ignoring: !showVideoControls,
                child: AnimatedOpacity(
                  opacity: showVideoControls && !isLock ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      // 返回
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          if (_isFullScreen) {
                            setState(() {
                              _isFullScreen = false;
                            });
                            _toggleFullScreen();
                          } else {
                            context.pop();
                          }
                        },
                      ),
                      // 标题
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  child: SimpleGestureDetector(
                    swipeConfig: SimpleSwipeConfig(
                      horizontalThreshold: 5,
                      swipeDetectionBehavior: SwipeDetectionBehavior.continuous,
                    ),
                    onTap: () => setState(() {
                      _showVideoControlsTimer();
                      showVideoControls = !showVideoControls;
                    }),
                    onDoubleTap: () {
                      isPlaying ? player.pause() : player.play();
                      _showVideoControlsTimer();
                    },
                    onHorizontalSwipe: (direction) =>
                        handleVideoProgressChange(direction),
                    child: Row(
                      children: [
                        Flexible(
                          child: SimpleGestureDetector(
                            swipeConfig: SimpleSwipeConfig(
                              verticalThreshold: 1,
                              horizontalThreshold: 9999,
                              swipeDetectionBehavior:
                                  SwipeDetectionBehavior.continuous,
                            ),
                            onVerticalSwipe: (direction) {
                              if (direction == SwipeDirection.left ||
                                  direction == SwipeDirection.right) {
                                return;
                              }
                              decreaseBrightnessBy1Percent(direction);
                            },

                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        Flexible(
                          child: SimpleGestureDetector(
                            swipeConfig: SimpleSwipeConfig(
                              verticalThreshold: 1,
                              horizontalThreshold: 9999,
                              swipeDetectionBehavior:
                                  SwipeDetectionBehavior.continuous,
                            ),
                            onVerticalSwipe: (direction) {
                              if (direction == SwipeDirection.left ||
                                  direction == SwipeDirection.right) {
                                return;
                              }
                              decreaseVolumeBy1Percent(direction);
                            },

                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !showVideoControls,
                child: AnimatedOpacity(
                  opacity: showVideoControls && !isLock ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  duration: Duration(milliseconds: 100),
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
                              value: widget.controller.value.position.inSeconds
                                  .toDouble(),
                              max: widget.controller.value.duration.inSeconds
                                  .toDouble(),
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
                          //剧集列表
                          if (_isFullScreen) ...[
                            IconButton(
                              onPressed: () {
                                _showVideoControlsTimer();
                              },
                              icon: Icon(
                                Icons.format_list_bulleted_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          //进度
                          Text(
                            "${widget.controller.value.position.inMinutes}:${widget.controller.value.position.inSeconds.remainder(60)}/${widget.controller.value.duration.inMinutes}:${widget.controller.value.duration.inSeconds.remainder(60)}",
                            style: TextStyle(color: Colors.white),
                          ),

                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: PopupMenuButton(
                              child: Badge(
                                backgroundColor: Colors.transparent,
                                label: Text(
                                  widget.controller.value.playbackSpeed
                                      .toString(),
                                ),
                                child: Icon(
                                  Icons.speed_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 2.0,
                                  child: Text('2.0x'),
                                  onTap: () =>
                                      widget.controller.setPlaybackSpeed(2.0),
                                ),
                                PopupMenuItem(
                                  value: 1.5,
                                  child: Text('1.5x'),
                                  onTap: () =>
                                      widget.controller.setPlaybackSpeed(1.5),
                                ),
                                PopupMenuItem(
                                  value: 1.25,
                                  child: Text('1.25x'),
                                  onTap: () =>
                                      widget.controller.setPlaybackSpeed(1.25),
                                ),
                                PopupMenuItem(
                                  value: 1.0,
                                  child: Text('1.0x'),
                                  onTap: () =>
                                      widget.controller.setPlaybackSpeed(1.0),
                                ),
                                PopupMenuItem(
                                  value: 0.75,
                                  child: Text('0.75x'),
                                  onTap: () =>
                                      widget.controller.setPlaybackSpeed(0.75),
                                ),
                                PopupMenuItem(
                                  value: 0.5,
                                  child: Text('0.5x'),
                                  onTap: () =>
                                      widget.controller.setPlaybackSpeed(0.5),
                                ),
                              ],
                            ),
                          ),
                          //弹幕
                          // IconButton(
                          //   onPressed: () {
                          //     _showVideoControlsTimer();
                          //   },
                          //   icon: Text(
                          //     '弹',
                          //     style: TextStyle(color: Colors.white),
                          //   ),
                          // ),
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              _showVideoControlsTimer();
                              setState(() {
                                _isFullScreen = !_isFullScreen;
                              });
                              _toggleFullScreen();
                            },
                            icon: Icon(
                              _isFullScreen
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
            ],
          ),
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
          AnimatedOpacity(
            opacity: showVideoControls ? 1 : 0,
            duration: Duration(milliseconds: 100),
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "${DateTime.now().hour}:${DateTime.now().minute}",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
