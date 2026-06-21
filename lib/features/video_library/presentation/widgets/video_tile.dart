// lib/features/video_library/presentation/widgets/video_tile.dart
import 'package:flutter/material.dart';
import 'package:video_library/features/video_library/data/video_model.dart';
import 'package:video_library/features/video_library/domain/video_duration_loader.dart';

class VideoTile extends StatelessWidget {
  final VideoModel video;
  final bool isWatched;
  final VoidCallback onTap;

  const VideoTile({
    Key? key,
    required this.video,
    required this.isWatched,
    required this.onTap,
  }) : super(key: key);

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _thumb() {
    if (video.thumbnailPath == null || video.thumbnailPath!.isEmpty) {
      return const CircleAvatar(radius: 24, child: Icon(Icons.play_arrow));
    }
    return Image.asset(
      video.thumbnailPath!,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const CircleAvatar(radius: 24, child: Icon(Icons.play_arrow)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Duration?>(
      future: VideoDurationLoader.load(video),
      builder: (context, snap) {
        final subtitle =
        (snap.connectionState == ConnectionState.done && snap.data != null)
            ? _fmt(snap.data!)
            : 'â€”:â€”';
        return ListTile(
          leading: Hero(tag: 'video-${video.id}', child: _thumb()),
          title: Text(video.title),
          subtitle: Text(subtitle),
          trailing: isWatched
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          onTap: onTap,
        );
      },
    );
  }
}
