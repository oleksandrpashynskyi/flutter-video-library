// lib/main.dart
import 'package:flutter/material.dart';
import 'package:video_library/core/themes/app_theme.dart';
import 'package:video_library/features/video_library/presentation/video_list_screen.dart';

void main() {
  runApp(const VideoApp());
}

class VideoApp extends StatelessWidget {
  const VideoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Library',
      theme: AppTheme.lightTheme,
      home: const VideoListScreen(),
    );
  }
}
