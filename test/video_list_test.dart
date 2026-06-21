// test/video_list_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:video_library/main.dart';

void main() {
  testWidgets('Video list loads and shows first item', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoApp());
    await tester.pumpAndSettle();

    expect(find.text('Influencer: Outfits'), findsOneWidget);
  });
}
