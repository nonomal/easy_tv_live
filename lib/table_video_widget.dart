import 'package:easy_tv_live/util/env_util.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:easy_tv_live/widget/video_hold_bg.dart';
import 'package:easy_tv_live/widget/volume_brightness_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

class TableVideoWidget extends StatefulWidget {
  final VideoPlayerController? controller;
  final GestureTapCallback? changeChannelSources;
  final String? toastString;
  final bool isLandscape;
  final bool isBuffering;
  final bool isPlaying;
  final double aspectRatio;
  const TableVideoWidget(
      {Key? key,
      required this.controller,
      required this.isBuffering,
      required this.isPlaying,
      required this.aspectRatio,
      this.toastString,
      this.changeChannelSources,
      this.isLandscape = true})
      : super(key: key);

  @override
  State<TableVideoWidget> createState() => _TableVideoWidgetState();
}

class _TableVideoWidgetState extends State<TableVideoWidget> with WindowListener {
  bool _isShowMenuBar = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() {
    super.onWindowEnterFullScreen();
    windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (widget.isLandscape) {
      windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    } else {
      windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
    }
  }

  @override
  void onWindowResize() {
    LogUtil.v('onWindowResize:::::${widget.isLandscape}');
    if (widget.isLandscape) {
      windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    } else {
      windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.isLandscape
              ? () {
                  _isShowMenuBar = !_isShowMenuBar;
                  setState(() {});
                }
              : null,
          onDoubleTap: () {
            if (widget.isPlaying) {
              widget.controller?.pause();
            } else {
              widget.controller?.play();
            }
          },
          child: Container(
            alignment: Alignment.center,
            color: Colors.black,
            child: widget.controller?.value.isInitialized ?? false
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: widget.aspectRatio,
                        child: SizedBox(
                          width: double.infinity,
                          child: VideoPlayer(widget.controller!),
                        ),
                      ),
                      if (!widget.isPlaying)
                        GestureDetector(
                            onTap: () {
                              widget.controller?.play();
                            },
                            child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 50)),
                      if (widget.isBuffering) const SpinKitSpinningLines(color: Colors.white)
                    ],
                  )
                : VideoHoldBg(toastString: widget.toastString),
          ),
        ),
        const VolumeBrightnessWidget(),
        if (widget.isLandscape)
          AnimatedPositioned(
              left: 0,
              right: 0,
              bottom: _isShowMenuBar || !widget.isPlaying ? 20 : -50,
              duration: const Duration(milliseconds: 100),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                        tooltip: '频道列表',
                        style: IconButton.styleFrom(backgroundColor: Colors.black87, side: const BorderSide(color: Colors.white)),
                        icon: const Icon(
                          Icons.list_alt,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isShowMenuBar = false;
                          });
                          Scaffold.of(context).openDrawer();
                        }),
                    const SizedBox(width: 12),
                    IconButton(
                        tooltip: '切换线路',
                        style: IconButton.styleFrom(backgroundColor: Colors.black87, side: const BorderSide(color: Colors.white)),
                        icon: const Icon(
                          Icons.legend_toggle,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isShowMenuBar = false;
                          });
                          widget.changeChannelSources?.call();
                        }),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: '竖屏模式',
                      onPressed: () async {
                        if (EnvUtil.isMobile()) {
                          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                          return;
                        }
                        await windowManager.setSize(const Size(375, 667), animate: true);
                        await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
                        Future.delayed(const Duration(milliseconds: 500), () => windowManager.center(animate: true));
                      },
                      style: IconButton.styleFrom(backgroundColor: Colors.black87, side: const BorderSide(color: Colors.white)),
                      icon: const Icon(
                        Icons.screen_rotation,
                        color: Colors.white,
                      ),
                    ),
                    if (!EnvUtil.isMobile()) const SizedBox(width: 12),
                    if (!EnvUtil.isMobile())
                      IconButton(
                        tooltip: '全屏切换',
                        onPressed: () async {
                          final isFullScreen = await windowManager.isFullScreen();
                          LogUtil.v('isFullScreen:::::$isFullScreen');
                          windowManager.setFullScreen(!isFullScreen);
                        },
                        style: IconButton.styleFrom(backgroundColor: Colors.black87, side: const BorderSide(color: Colors.white)),
                        icon: FutureBuilder<bool>(
                          future: windowManager.isFullScreen(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Icon(
                                snapshot.data! ? Icons.close_fullscreen : Icons.fit_screen_outlined,
                                color: Colors.white,
                              );
                            } else {
                              return const Icon(
                                Icons.fit_screen_outlined,
                                color: Colors.white,
                              );
                            }
                          },
                        ),
                      )
                  ],
                ),
              )),
        if (!widget.isLandscape)
          Positioned(
            right: 15,
            bottom: 15,
            child: IconButton(
              tooltip: '横屏模式',
              onPressed: () async {
                if (EnvUtil.isMobile()) {
                  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                  return;
                }
                await windowManager.setSize(const Size(800, 800 * 9 / 16), animate: true);
                await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
                Future.delayed(const Duration(milliseconds: 500), () => windowManager.center(animate: true));
              },
              style: IconButton.styleFrom(backgroundColor: Colors.black45, iconSize: 20),
              icon: const Icon(Icons.screen_rotation, color: Colors.white),
            ),
          )
      ],
    );
  }
}
