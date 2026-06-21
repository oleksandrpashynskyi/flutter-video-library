// lib/features/video_library/presentation/widgets/video_controls_overlay.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onInteraction;
  final VoidCallback onFullscreen;

  const VideoControlsOverlay({
    Key? key,
    required this.controller,
    required this.onInteraction,
    required this.onFullscreen,
  }) : super(key: key);

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds whenever controller value changes
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        final pos = v.position;
        final dur = v.duration;
        final totalMs = (dur.inMilliseconds <= 0) ? 1 : dur.inMilliseconds;
        final valueMs = pos.inMilliseconds.clamp(0, totalMs);

        return Container(
          color: Colors.black45,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Top row: playback speed + mute
              Row(
                children: [
                  PopupMenuButton<double>(
                    tooltip: 'Speed',
                    onOpened: onInteraction,
                    onSelected: (s) async {
                      onInteraction();
                      await controller.setPlaybackSpeed(s);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0.5, child: Text('0.5×')),
                      PopupMenuItem(value: 1.0, child: Text('1.0×')),
                      PopupMenuItem(value: 1.5, child: Text('1.5×')),
                      PopupMenuItem(value: 2.0, child: Text('2.0×')),
                    ],
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('${v.playbackSpeed.toStringAsFixed(1)}×',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: v.volume == 0 ? 'Unmute' : 'Mute',
                    icon: Icon(v.volume == 0 ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white),
                    onPressed: () async {
                      onInteraction();
                      await controller.setVolume(v.volume == 0 ? 1.0 : 0.0);
                    },
                  ),
                ],
              ),

              // Middle row: play/pause, ±10s, fullscreen
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      v.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      onInteraction();
                      v.isPlaying ? controller.pause() : controller.play();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () async {
                      onInteraction();
                      final newPos = pos - const Duration(seconds: 10);
                      await controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () async {
                      onInteraction();
                      final end = dur;
                      final newPos = pos + const Duration(seconds: 10);
                      await controller.seekTo(newPos > end ? end : newPos);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {
                      onInteraction();
                      onFullscreen();
                    },
                  ),
                ],
              ),

              // Bottom row: time + slider
              Row(
                children: [
                  Text(_fmt(pos), style: const TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: totalMs.toDouble(),
                      value: valueMs.toDouble(),
                      onChanged: (vMs) {
                        onInteraction();
                        controller.seekTo(Duration(milliseconds: vMs.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white54,
                    ),
                  ),
                  Text(_fmt(dur), style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
