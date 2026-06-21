// lib/features/video_library/presentation/video_player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // rootBundle, SystemChrome, Shortcuts, etc.
import 'package:video_player/video_player.dart';
import 'package:video_library/features/video_library/data/video_model.dart';
import 'package:video_library/features/video_library/presentation/widgets/video_controls_overlay.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  bool _showControls = true;
  bool _hovering = false;
  Timer? _hideTimer;

  static const _hideDelay = Duration(seconds: 3);
  static const _endTolerance = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.video.source == VideoSource.asset) {
        await rootBundle.load(widget.video.path); // prove bundling
        _controller = VideoPlayerController.asset(widget.video.path);
      } else {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.video.path));
      }

      await _controller.initialize();
      if (!mounted) return;

      setState(() => _initialized = true);
      _controller.play();
      _controller.addListener(_onControllerTick);

      _restartHideTimer();
    } catch (e) {
      setState(() => _error = 'Initialization failed: $e');
    }
  }

  void _onControllerTick() {
    if (!mounted) return;
    final v = _controller.value;
    if (v.hasError) {
      setState(() => _error = v.errorDescription);
      return;
    }
    if (_isEnded(v)) {
      _hideTimer?.cancel();
      if (!_showControls) setState(() => _showControls = true);
    }
  }

  bool _isEnded(VideoPlayerValue v) {
    if (!v.isInitialized || v.duration == Duration.zero) return false;
    final atOrPastEnd = v.position + _endTolerance >= v.duration;
    return !v.isPlaying && atOrPastEnd;
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (_hovering) return; // keep visible while hovering (desktop/web)
    if (_initialized && _isEnded(_controller.value)) return; // keep visible at end
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _onUserInteraction() {
    if (!_showControls) setState(() => _showControls = true);
    _restartHideTimer();
  }

  Future<void> _seekRelative(Duration delta) async {
    final v = _controller.value;
    final end = v.duration;
    var target = v.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > end) target = end;
    await _controller.seekTo(target);
  }

  Future<void> _enterFullscreen() async {
    // Lock landscape & hide system UI
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => FullscreenVideoPage(
          controller: _controller,
          heroTag: 'video-${widget.video.id}',
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

    if (!mounted) return; // avoid context-after-await lint
    // Restore after returning (also restored inside fullscreen for robustness)
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    _onUserInteraction();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_initialized || _error != null) {
      _controller.removeListener(_onControllerTick);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err =
        _error ?? (_initialized ? _controller.value.errorDescription : null);

    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: Center(
        child: err != null
            ? Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Video error:\n$err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        )
            : _initialized
            ? Hero(
          tag: 'video-${widget.video.id}',
          child: Material(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: MouseRegion(
                onEnter: (_) {
                  _hovering = true;
                  if (!_showControls) {
                    setState(() => _showControls = true);
                  }
                  _hideTimer?.cancel();
                },
                onHover: (_) {
                  if (!_showControls) {
                    setState(() => _showControls = true);
                  }
                  _hideTimer?.cancel();
                },
                onExit: (_) {
                  _hovering = false;
                  _restartHideTimer();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Only the video has gestures; overlay buttons wonâ€™t toggle it
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onUserInteraction,
                      onDoubleTapDown: (details) async {
                        final rb = context.findRenderObject()
                        as RenderBox?;
                        final w = rb?.size.width ?? 1;
                        final isRight =
                            details.localPosition.dx > w / 2;
                        await _seekRelative(Duration(
                            seconds: isRight ? 10 : -10));
                        _onUserInteraction();
                      },
                      child: VideoPlayer(_controller),
                    ),

                    // Controls overlay
                    AnimatedOpacity(
                      opacity: _showControls ? 1 : 0,
                      duration:
                      const Duration(milliseconds: 180),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: VideoControlsOverlay(
                          controller: _controller,
                          onInteraction: _onUserInteraction,
                          onFullscreen: _enterFullscreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// Intent for ESC to exit fullscreen
class _ExitFullscreenIntent extends Intent {
  const _ExitFullscreenIntent();
}

/// Fullscreen page that REUSES the same controller and shows overlay + a close button.
/// Restores system UI/orientation BEFORE popping and handles ESC/back.
class FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String heroTag;
  const FullscreenVideoPage({
    Key? key,
    required this.controller,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  bool _showControls = true;
  bool _hovering = false;
  Timer? _hideTimer;

  static const _hideDelay = Duration(seconds: 3);
  static const _endTolerance = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    _restartHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final v = widget.controller.value;
    if (v.hasError) {
      setState(() => _showControls = true);
      return;
    }
    // Keep controls visible when ended
    final ended = v.isInitialized &&
        v.duration != Duration.zero &&
        !v.isPlaying &&
        (v.position + _endTolerance >= v.duration);
    if (ended) {
      _hideTimer?.cancel();
      if (!_showControls) setState(() => _showControls = true);
    }
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (_hovering) return;
    final v = widget.controller.value;
    final ended = v.isInitialized &&
        v.duration != Duration.zero &&
        !v.isPlaying &&
        (v.position + _endTolerance >= v.duration);
    if (ended) return;
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  Future<void> _restoreSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  void _onInteraction() {
    if (!_showControls) setState(() => _showControls = true);
    _restartHideTimer();
  }

  Future<void> _seekRelative(Duration delta) async {
    final v = widget.controller.value;
    var target = v.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > v.duration) target = v.duration;
    await widget.controller.seekTo(target);
  }

  Future<void> _exitFullscreen() async {
    // Avoid use_build_context_synchronously: capture navigator first
    final navigator = Navigator.of(context);
    await _restoreSystemUI();
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.controller.value;

    return PopScope(
      onPopInvoked: (didPop) async {
        // Always restore UI when leaving
        await _restoreSystemUI();
      },
      child: Shortcuts(
        shortcuts: {
          // ESC to exit fullscreen on desktop/web
          LogicalKeySet(LogicalKeyboardKey.escape):
          const _ExitFullscreenIntent(),
        },
        child: Actions(
          actions: {
            _ExitFullscreenIntent:
            CallbackAction<_ExitFullscreenIntent>(onInvoke: (e) {
              _exitFullscreen();
              return null;
            }),
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: MouseRegion(
                onEnter: (_) {
                  _hovering = true;
                  if (!_showControls) setState(() => _showControls = true);
                  _hideTimer?.cancel();
                },
                onHover: (_) {
                  if (!_showControls) setState(() => _showControls = true);
                  _hideTimer?.cancel();
                },
                onExit: (_) {
                  _hovering = false;
                  _restartHideTimer();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onInteraction,
                      onDoubleTapDown: (details) async {
                        final rb =
                        context.findRenderObject() as RenderBox?;
                        final w = rb?.size.width ?? 1;
                        final right = details.localPosition.dx > w / 2;
                        await _seekRelative(
                            Duration(seconds: right ? 10 : -10));
                        _onInteraction();
                      },
                      child: v.isInitialized
                          ? Center(
                        child: Hero(
                          tag: widget.heroTag,
                          child: AspectRatio(
                            aspectRatio: v.aspectRatio,
                            child: VideoPlayer(widget.controller),
                          ),
                        ),
                      )
                          : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      ),
                    ),

                    // Close (exit) button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _exitFullscreen,
                        tooltip: 'Exit fullscreen',
                      ),
                    ),

                    // Overlay controls
                    AnimatedOpacity(
                      opacity: _showControls ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: VideoControlsOverlay(
                            controller: widget.controller,
                            onInteraction: _onInteraction,
                            onFullscreen: _exitFullscreen, // exits in fullscreen
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
