// Basic smoke test for Food Inventory.

import 'package:flutter_test/flutter_test.dart';

import 'package:food_inventory/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodInventoryApp());
    // Verify the bottom nav shows both tabs.
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });
}
