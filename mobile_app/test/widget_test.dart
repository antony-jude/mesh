import 'package:flutter_test/flutter_test.dart';
import 'package:meshlink/main.dart';

void main() {
  testWidgets('MeshLink app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MeshLinkApp());

    expect(find.byType(MeshLinkApp), findsOneWidget);
  });
}