// Tests for FoodInventoryApp and HomePage (main.dart).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_inventory/firestore_service.dart';
import 'package:food_inventory/main.dart';

void main() {
  setUp(() {
    FirestoreService.instance.setFirestoreInstance(FakeFirebaseFirestore());
    FirestoreService.instance.setUid('test-uid');
  });

  group('FoodInventoryApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'SUGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('uses Material 3 theming', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme!.useMaterial3, isTrue);
    });

    testWidgets('uses light theme only', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme!.brightness, Brightness.light);
    });
  });

  group('HomePage', () {
    testWidgets('shows bottom navigation with FAB and two tabs', (
      tester,
    ) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsWidgets);
      expect(find.text('Scanner'), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows inventory icons', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('starts on inventory tab', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      // Inventory page shows the app title
      expect(find.text('SUGO'), findsWidgets);
      // Empty state message visible
      expect(find.text('No products yet'), findsOneWidget);
    });

    testWidgets('navigating to Scanner tab and back works', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      // Tap Scanner tab
      await tester.tap(find.text('Scanner'));
      await tester.pump();

      // Tap Inventory tab again
      await tester.tap(find.text('Inventory').first);
      await tester.pumpAndSettle();

      expect(find.text('No products yet'), findsOneWidget);
    });

    testWidgets('uses IndexedStack to preserve state', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      expect(find.byType(IndexedStack), findsOneWidget);
    });
  });
}
