import 'package:flutter_test/flutter_test.dart';
import 'package:kisandrive_mobile/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TracktorMobileApp());
    expect(find.byType(TracktorMobileApp), findsOneWidget);
  });
}
