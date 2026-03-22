// Basic smoke test for Food Inventory.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_inventory/firestore_service.dart';
import 'package:food_inventory/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Inject a fake Firestore so no real backend is needed.
    FirestoreService.instance.setFirestoreInstance(FakeFirebaseFirestore());

    await tester.pumpWidget(const FoodInventoryApp());
    await tester.pumpAndSettle();

    // Verify the bottom nav shows both tabs.
    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Scan'), findsOneWidget);
  });
}
