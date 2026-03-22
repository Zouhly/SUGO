// Tests for FoodInventoryApp and HomePage (main.dart).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_inventory/firestore_service.dart';
import 'package:food_inventory/main.dart';

void main() {
  setUp(() {
    FirestoreService.instance.setFirestoreInstance(FakeFirebaseFirestore());
  });

  group('FoodInventoryApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Food Inventory');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('uses Material 3 theming', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme!.useMaterial3, isTrue);
      expect(materialApp.darkTheme!.useMaterial3, isTrue);
    });

    testWidgets('uses system theme mode', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.system);
    });
  });

  group('HomePage', () {
    testWidgets('shows bottom navigation with two tabs', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsWidgets);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('shows inventory icons', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_outlined), findsOneWidget);
    });

    testWidgets('starts on inventory tab', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      // Inventory page should be visible (search bar present)
      expect(find.text('Search products…'), findsOneWidget);
    });

    testWidgets('navigating to Scan tab and back works', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      // Tap Scan tab
      await tester.tap(find.text('Scan'));
      await tester.pump();

      // Tap Inventory tab again
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Search products…'), findsOneWidget);
    });

    testWidgets('uses IndexedStack to preserve state', (tester) async {
      await tester.pumpWidget(const FoodInventoryApp());
      await tester.pumpAndSettle();

      expect(find.byType(IndexedStack), findsOneWidget);
    });
  });
}
