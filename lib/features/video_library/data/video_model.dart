// lib/features/video_library/data/video_model.dart
enum VideoSource { asset, network }

class VideoModel {
  final String id;
  final String title;
  final VideoSource source;
  final String path;
  final String? thumbnailPath;

  const VideoModel({
    required this.id,
    required this.title,
    required this.source,
    required this.path,
    this.thumbnailPath,
  });
}
