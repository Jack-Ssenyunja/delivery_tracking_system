import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('shows role selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryApp());
    expect(find.text('Delivery Tracker'), findsOneWidget);
    expect(find.text('Rider App'), findsOneWidget);
    expect(find.text('Customer App'), findsOneWidget);
  });
}
