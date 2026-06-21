// lib/features/video_library/presentation/video_list_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_library/features/video_library/data/video_model.dart';
import 'package:video_library/features/video_library/domain/video_service.dart';
import 'package:video_library/features/video_library/presentation/video_player_screen.dart';
import 'package:video_library/features/video_library/presentation/widgets/video_grid_card.dart';
import 'package:video_library/features/video_library/presentation/widgets/video_tile.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final VideoService _service = const VideoService();
  late Future<List<VideoModel>> _videosFuture;
  Set<String> _watchedIds = {};
  String _query = '';
  bool _useGrid = true; // default to grid
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _videosFuture = _service.loadVideos();
    _loadWatched();
  }

  Future<void> _loadWatched() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _watchedIds = (prefs.getStringList('watchedVideos') ?? []).toSet();
    });
  }

  Future<void> _markWatched(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _watchedIds.add(id);
    await prefs.setStringList('watchedVideos', _watchedIds.toList());
    setState(() {});
  }

  Future<void> _refresh() async {
    setState(() {
      _videosFuture = _service.loadVideos();
    });
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  List<VideoModel> _filter(List<VideoModel> items) {
    if (_query.trim().isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((v) => v.title.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topBar = SliverAppBar(
      pinned: true,
      toolbarHeight: 56, // compact toolbar for mobile
      collapsedHeight: 56,
      title: const Text('Video Library'),
      actions: [
        IconButton(
          tooltip: _useGrid ? 'Switch to list' : 'Switch to grid',
          onPressed: () => setState(() => _useGrid = !_useGrid),
          icon: Icon(_useGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            height: 40, // smaller search field
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: 'Search videosâ€¦',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<VideoModel>>(
          future: _videosFuture,
          builder: (context, snap) {
            if (snap.hasError) {
              return CustomScrollView(
                slivers: [
                  topBar,
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Error: ${snap.error}')),
                  ),
                ],
              );
            }
            if (!snap.hasData) {
              return CustomScrollView(
                slivers: [
                  topBar,
                  const _ShimmerGrid(),
                ],
              );
            }

            final videos = _filter(snap.data!);

            return CustomScrollView(
              slivers: [
                topBar,
                if (videos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied,
                            size: 48, color: Theme.of(context).hintColor),
                        const SizedBox(height: 8),
                        Text('No results for â€œ$_queryâ€',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 24),
                      ],
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    // IMPORTANT: Provide a sliver here (no AnimatedSwitcher in a sliver)
                    sliver: _useGrid ? _gridSliver(videos) : _listSliver(videos),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Responsive grid (tight for phones)
  Widget _gridSliver(List<VideoModel> videos) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 560 ? 2 : 1;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
            (context, i) {
          final v = videos[i];
          final watched = _watchedIds.contains(v.id);
          return VideoGridCard(
            video: v,
            watched: watched,
            heroTag: 'video-${v.id}',
            onTap: () async {
              final completed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)),
              );
              if (completed == true) _markWatched(v.id);
            },
          );
        },
        childCount: videos.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
      ),
    );
  }

  // List sliver
  Widget _listSliver(List<VideoModel> videos) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, i) {
          final v = videos[i];
          final watched = _watchedIds.contains(v.id);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: VideoTile(
              video: v,
              isWatched: watched,
              onTap: () async {
                final completed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)),
                );
                if (completed == true) _markWatched(v.id);
              },
            ),
          );
        },
        childCount: videos.length,
      ),
    );
  }
}

// Simple shimmer while loading â€” no packages
class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cross = width >= 560 ? 2 : 1;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
            (context, i) => const _ShimmerCell(),
        childCount: cross * 2,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
      ),
    );
  }
}

class _ShimmerCell extends StatefulWidget {
  const _ShimmerCell();

  @override
  State<_ShimmerCell> createState() => _ShimmerCellState();
}

class _ShimmerCellState extends State<_ShimmerCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final base = Colors.black.withOpacity(0.06);
        final hi = Colors.black.withOpacity(0.12);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [base, hi, base],
                stops: const [0.1, 0.5, 0.9],
                begin: Alignment(-1 + t, 0),
                end: Alignment(t, 0),
              ),
            ),
          ),
        );
      },
    );
  }
}
