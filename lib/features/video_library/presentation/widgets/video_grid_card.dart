// lib/features/video_library/presentation/widgets/video_grid_card.dart
import 'package:flutter/material.dart';
import 'package:video_library/features/video_library/data/video_model.dart';
import 'package:video_library/features/video_library/domain/video_duration_loader.dart';

class VideoGridCard extends StatelessWidget {
  final VideoModel video;
  final bool watched;
  final String heroTag;
  final VoidCallback onTap;

  const VideoGridCard({
    Key? key,
    required this.video,
    required this.watched,
    required this.heroTag,
    required this.onTap,
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
    final String? thumb = video.thumbnailPath;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or gradient fallback (null-safe)
            Hero(
              tag: heroTag,
              child: (thumb == null || thumb.isEmpty)
                  ? _GradientFallback(title: video.title)
                  : Image.asset(
                thumb, // non-null here
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _GradientFallback(title: video.title),
              ),
            ),

            // Legibility overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),

            // Title + REAL duration (from loader, not model)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<Duration?>(
                      future: VideoDurationLoader.load(video),
                      builder: (context, snap) {
                        final text = (snap.hasData && snap.data != null)
                            ? _fmt(snap.data!)
                            : 'â€”:â€”';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Watched badge
            if (watched)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Watched',
                          style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  final String title;
  const _GradientFallback({required this.title});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cc.secondaryContainer, cc.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cc.onPrimaryContainer,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
