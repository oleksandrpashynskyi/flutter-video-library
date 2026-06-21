# Flutter Video Library

A Flutter app that presents a searchable library of videos in a grid or list, and plays them in a custom full-screen player. Videos are loaded from bundled assets and from the network, and the app remembers which ones you've watched.

## What it is / What it does

The app opens on a **video library screen** and lets you:

- **Browse** a catalog of videos as a **grid or a list** (toggleable; defaults to grid).
- **Search/filter** videos by title.
- **Pull to refresh** the catalog.
- See **per-video thumbnails and durations** — durations are read from each video once and cached.
- Track **watched videos** — once you open a video it's marked watched, and that state persists across launches via `shared_preferences`.

Tapping a video opens the **player screen**, which:

- Plays **asset-bundled** videos and **network** videos (the catalog includes one streamed clip from Flutter's public sample assets).
- Shows a **custom controls overlay** (play/pause, progress) that **auto-hides after a few seconds** and reappears on interaction/hover.
- Handles initialization **errors** gracefully and detects end-of-playback.

The catalog ships with 6 bundled sample clips plus 1 network clip, defined in `VideoService`.

## Tech stack

- **Framework:** Flutter (Material Design)
- **Language:** Dart (SDK `>=2.17.0 <3.0.0`)
- **Packages:** [`video_player`](https://pub.dev/packages/video_player) (playback), [`shared_preferences`](https://pub.dev/packages/shared_preferences) (persisting watched state)
- **Platforms:** Android, iOS, web, Windows, macOS, Linux (standard Flutter targets)

## Project structure

The code follows a feature-first, layered architecture:

```
flutter-video-library/
├── pubspec.yaml                # package name (video_library), deps, asset registration
├── assets/
│   ├── videos/                 # bundled .mp4 sample clips
│   └── thumbnails/             # .png thumbnails
└── lib/
    ├── main.dart               # app entry point (VideoApp → VideoListScreen)
    ├── core/
    │   ├── constants/app_constants.dart   # asset prefixes, network URL
    │   ├── themes/app_theme.dart           # light theme
    │   └── utils/format_utils.dart         # duration formatting
    └── features/video_library/
        ├── data/video_model.dart            # VideoModel + VideoSource (asset/network)
        ├── domain/
        │   ├── video_service.dart           # the catalog (source of truth)
        │   └── video_duration_loader.dart   # loads + caches durations, dedupes in-flight loads
        └── presentation/
            ├── video_list_screen.dart       # grid/list, search, refresh, watched state
            ├── video_player_screen.dart      # player + lifecycle/error handling
            └── widgets/
                ├── video_grid_card.dart
                ├── video_tile.dart
                └── video_controls_overlay.dart
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 2.17+)
- A target device, emulator, or browser

## Run

```bash
flutter pub get
flutter run
```

To target a specific platform, e.g.:

```bash
flutter run -d chrome      # web
flutter run -d windows     # Windows desktop
```

## Notes

- The Dart package is named `video_library`; imports use `package:video_library/...`.
- The network sample clip is Flutter's public `bee.mp4`; the rest are bundled under `assets/videos/`.
