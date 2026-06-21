// lib/features/video_library/domain/video_service.dart
import 'package:video_library/features/video_library/data/video_model.dart';

class VideoService {
  const VideoService();

  Future<List<VideoModel>> loadVideos() async {
    return const [
      VideoModel(
        id: '1',
        title: 'Influencer: Outfits',
        source: VideoSource.asset,
        path: 'assets/videos/influencer.mp4',
        thumbnailPath: 'assets/thumbnails/influencer.png',
      ),
      VideoModel(
        id: '2',
        title: 'Boxing Practice',
        source: VideoSource.asset,
        path: 'assets/videos/boxing.mp4',
        thumbnailPath: 'assets/thumbnails/boxing.png',
      ),
      VideoModel(
        id: '3',
        title: 'Bike Ride',
        source: VideoSource.asset,
        path: 'assets/videos/bike.mp4',
        thumbnailPath: 'assets/thumbnails/bike.png',
      ),
      VideoModel(
        id: '4',
        title: 'Rain Drop',
        source: VideoSource.asset,
        path: 'assets/videos/rain.mp4',
        thumbnailPath: 'assets/thumbnails/rain.png',
      ),
      VideoModel(
        id: '5',
        title: 'Rabbit Hobbit',
        source: VideoSource.asset,
        path: 'assets/videos/rabbit.mp4',
        thumbnailPath: 'assets/thumbnails/rabbit.png',
      ),
      VideoModel(
        id: '6',
        title: 'Leggo Show',
        source: VideoSource.asset,
        path: 'assets/videos/leggo.mp4',
        thumbnailPath: 'assets/thumbnails/leggo.png',
      ),
      VideoModel(
        id: '7',
        title: 'Bee (network)',
        source: VideoSource.network,
        path: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        thumbnailPath: 'assets/thumbnails/bee.png',
      ),
    ];
  }
}
