// lib/features/video_library/domain/video_duration_loader.dart
import 'dart:async';
import 'dart:collection';
import 'package:video_player/video_player.dart';
import 'package:video_library/features/video_library/data/video_model.dart';

/// Loads the real duration of a video (asset or network) once and caches it.
/// Prevents duplicate in-flight inits for the same source/path.
class VideoDurationLoader {
  static final Map<String, Duration> _cache = HashMap();
  static final Map<String, Future<Duration?>> _inFlight = HashMap();

  static String _key(VideoModel v) => '${v.source}:${v.path}';

  static Future<Duration?> load(VideoModel video) {
    final key = _key(video);

    // Cached result
    if (_cache.containsKey(key)) return Future.value(_cache[key]);

    // Existing in-flight load
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final completer = Completer<Duration?>();
    _inFlight[key] = completer.future;

    () async {
      VideoPlayerController? c;
      try {
        c = (video.source == VideoSource.asset)
            ? VideoPlayerController.asset(video.path)
            : VideoPlayerController.networkUrl(Uri.parse(video.path));

        await c.initialize();
        final d = c.value.duration;
        _cache[key] = d;
        completer.complete(d);
      } catch (_) {
        completer.complete(null);
      } finally {
        try {
          await c?.dispose();
    } catch (_) {}
    _inFlight.remove(key);
    }
    }();

    return completer.future;
  }
}
