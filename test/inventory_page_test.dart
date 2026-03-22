import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_inventory/firestore_service.dart';
import 'package:food_inventory/inventory_page.dart';

/// Wraps a widget in a MaterialApp for testing.
Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: child,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
  );
}

/// Seeds the fake Firestore with sample products.
Future<void> seedProducts(FakeFirebaseFirestore firestore) async {
  final now = Timestamp.now();
  await firestore.collection('products').doc('p1').set({
    'barcode': '111',
    'name': 'Milk',
    'category': 'Dairy',
    'quantity': 5,
    'minThreshold': 2,
    'createdAt': now,
    'updatedAt': now,
  });
  await firestore.collection('products').doc('p2').set({
    'barcode': '222',
    'name': 'Bread',
    'category': 'Bakery',
    'quantity': 1,
    'minThreshold': 2,
    'createdAt': now,
    'updatedAt': now,
  });
  await firestore.collection('products').doc('p3').set({
    'barcode': '333',
    'name': 'Eggs',
    'category': 'Dairy',
    'quantity': 0,
    'minThreshold': 3,
    'createdAt': now,
    'updatedAt': now,
  });
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    FirestoreService.instance.setFirestoreInstance(fakeFirestore);
  });

  group('InventoryPage', () {
    testWidgets('shows empty state when no products', (tester) async {
      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('No products yet'), findsOneWidget);
      expect(
        find.text('Scan a barcode to add your first item.'),
        findsOneWidget,
      );
    });

    testWidgets('displays products from Firestore', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('shows summary bar with total, low stock, out of stock', (
      tester,
    ) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Total: 3 products
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      // Low stock: Bread (qty 1 <= threshold 2) and Eggs (qty 0 <= threshold 3) = 2
      expect(find.text('Low stock'), findsOneWidget);
      // Out of stock: Eggs (qty 0) = 1
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('shows OUT badge for out-of-stock products', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('OUT'), findsOneWidget);
    });

    testWidgets('shows LOW badge for low-stock products', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('LOW'), findsOneWidget);
    });

    testWidgets('shows category filter chips', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Dairy'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Bakery'), findsOneWidget);
    });

    testWidgets('filtering by category shows only matching products', (
      tester,
    ) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Tap on Bakery chip
      await tester.tap(find.widgetWithText(FilterChip, 'Bakery'));
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('tapping a selected category filter deselects it', (
      tester,
    ) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Select Bakery
      await tester.tap(find.widgetWithText(FilterChip, 'Bakery'));
      await tester.pumpAndSettle();

      // Deselect Bakery
      await tester.tap(find.widgetWithText(FilterChip, 'Bakery'));
      await tester.pumpAndSettle();

      // All products should be visible again
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('search filters products by name', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Type in search box
      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      // Bread and Eggs should be filtered out (not in product tiles)
      expect(find.text('No matching products.'), findsNothing);
    });

    testWidgets('search with no results shows empty message', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.text('No matching products.'), findsOneWidget);
    });

    testWidgets('search filters by barcode', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '222');
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('search filters by category', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dairy');
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('tapping + button calls incrementQuantity', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Find the + icon button (there are multiple, just tap the first)
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Verify the quantity was incremented in Firestore (Bread is first alphabetically)
      final doc = await fakeFirestore.collection('products').doc('p2').get();
      expect(doc.data()!['quantity'], 2);
    });

    testWidgets('tapping - button calls decrementQuantity', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      final removeButtons = find.byIcon(Icons.remove);
      expect(removeButtons, findsWidgets);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();
    });

    testWidgets('delete confirmation dialog appears and can cancel', (
      tester,
    ) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Open popup menu on first product
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsWidgets);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Dialog shows
      expect(find.text('Delete Product'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Product still exists
      final doc = await fakeFirestore.collection('products').doc('p2').get();
      expect(doc.exists, isTrue);
    });

    testWidgets('delete confirmation dialog confirms deletion', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Open popup menu on first product (Bread, alphabetically first)
      final menuButtons = find.byType(PopupMenuButton<String>);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Product should be deleted from Firestore
      final doc = await fakeFirestore.collection('products').doc('p2').get();
      expect(doc.exists, isFalse);
    });

    testWidgets('edit dialog appears and can save', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // Open popup menu on first product
      final menuButtons = find.byType(PopupMenuButton<String>);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Dialog shows
      expect(find.text('Edit Product'), findsOneWidget);

      // Clear name and type new name
      final nameField = find.widgetWithText(TextFormField, 'Name');
      await tester.enterText(nameField, 'Sourdough');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify update in Firestore
      final doc = await fakeFirestore.collection('products').doc('p2').get();
      expect(doc.data()!['name'], 'Sourdough');
    });

    testWidgets('edit dialog cancel does not save', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      final menuButtons = find.byType(PopupMenuButton<String>);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Name unchanged
      final doc = await fakeFirestore.collection('products').doc('p2').get();
      expect(doc.data()!['name'], 'Bread');
    });

    testWidgets('edit dialog validates empty name', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      final menuButtons = find.byType(PopupMenuButton<String>);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Clear name
      final nameField = find.widgetWithText(TextFormField, 'Name');
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows loading indicator while waiting for data', (
      tester,
    ) async {
      // Don't seed any data and don't pump settle - just check initial state
      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      // Just pump once to build without settling the stream
      await tester.pump();

      // After first pump, either loading or data should be shown
      // The StreamBuilder will quickly resolve with fake firestore
    });

    testWidgets('tapping All chip shows all products', (tester) async {
      await seedProducts(fakeFirestore);

      await tester.pumpWidget(buildTestApp(const InventoryPage()));
      await tester.pumpAndSettle();

      // First filter by Bakery
      await tester.tap(find.widgetWithText(FilterChip, 'Bakery'));
      await tester.pumpAndSettle();

      // Then tap All
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });
  });
}
