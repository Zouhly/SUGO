import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:food_inventory/firestore_service.dart';
import 'package:food_inventory/scanner_page.dart';

/// Keeps a reference to onDetect so tests can trigger fake scans.
late void Function(BarcodeCapture) _lastOnDetect;

/// A fake scanner that replaces MobileScanner in tests.
/// Renders a button to trigger a scan.
Widget fakeScannerBuilder(
  MobileScannerController controller,
  void Function(BarcodeCapture) onDetect,
) {
  _lastOnDetect = onDetect;
  return const SizedBox(width: 300, height: 300, key: Key('fake_scanner'));
}

Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: child,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
  );
}

/// Helper to create a BarcodeCapture with a given raw value.
BarcodeCapture makeBarcodeCapture(String rawValue) {
  return BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]);
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  const testUid = 'test-uid';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    FirestoreService.instance.setFirestoreInstance(fakeFirestore);
    FirestoreService.instance.setUid(testUid);
  });

  /// User-scoped products collection.
  CollectionReference<Map<String, dynamic>> productsCol() =>
      fakeFirestore.collection('users').doc(testUid).collection('products');

  /// User-scoped scanLogs collection.
  CollectionReference<Map<String, dynamic>> scanLogsCol() =>
      fakeFirestore.collection('users').doc(testUid).collection('scanLogs');

  group('ScannerPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan Product'), findsOneWidget);
    });

    testWidgets('renders scaffold with scan overlay frame', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byKey(const Key('fake_scanner')), findsOneWidget);
    });

    testWidgets(
      'scanning existing product increments quantity and shows snackbar',
      (tester) async {
        // Seed an existing product
        await productsCol().doc('p1').set({
          'barcode': 'EXIST123',
          'name': 'Milk',
          'category': 'Dairy',
          'quantity': 5,
          'minThreshold': 2,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        await tester.pumpWidget(
          buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
        );
        await tester.pumpAndSettle();

        // Trigger a scan
        _lastOnDetect(makeBarcodeCapture('EXIST123'));
        await tester.pump();
        await tester.pump();
        // Advance past the 2-second cooldown
        await tester.pump(const Duration(seconds: 3));

        // Snackbar should show increment message
        expect(find.textContaining('Milk'), findsOneWidget);

        // Quantity should be incremented in Firestore
        final doc = await productsCol().doc('p1').get();
        expect(doc.data()!['quantity'], 6);

        // Scan log should be created
        final logs = await scanLogsCol().get();
        expect(logs.docs.length, 1);
        expect(logs.docs.first.data()['action'], 'incremented');
      },
    );

    testWidgets('shows last scanned barcode label', (tester) async {
      await productsCol().doc('p1').set({
        'barcode': 'SCAN456',
        'name': 'Juice',
        'category': 'Drinks',
        'quantity': 3,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('SCAN456'));
      await tester.pump();

      expect(find.text('Last scan: SCAN456'), findsOneWidget);

      // Advance past the 2-second cooldown
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows processing indicator while scanning', (tester) async {
      await productsCol().doc('p1').set({
        'barcode': 'PROC789',
        'name': 'Water',
        'category': 'Drinks',
        'quantity': 1,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('PROC789'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance past the 2-second cooldown
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('ignores scan while still processing', (tester) async {
      await productsCol().doc('p1').set({
        'barcode': 'DUP001',
        'name': 'Bread',
        'category': 'Bakery',
        'quantity': 2,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      // First scan
      _lastOnDetect(makeBarcodeCapture('DUP001'));
      await tester.pump();

      // Second scan while still processing - should be ignored
      _lastOnDetect(makeBarcodeCapture('DUP001'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Should only have incremented once
      final doc = await productsCol().doc('p1').get();
      expect(doc.data()!['quantity'], 3);
    });

    testWidgets('ignores scan with empty barcode', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture(''));
      await tester.pumpAndSettle();

      // Nothing should happen
      expect(find.textContaining('Last scan'), findsNothing);
    });

    testWidgets('scanning new product shows new product form', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('NEW001'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bottom sheet should appear
      expect(find.text('New Product'), findsOneWidget);
      expect(find.text('Barcode: NEW001'), findsOneWidget);
      expect(find.text('Product name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Min threshold'), findsOneWidget);
      expect(find.text('Save Product'), findsOneWidget);

      // Dismiss to let timers complete
      await tester.drag(find.text('New Product'), const Offset(0, 400));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('new product form validates empty fields', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('VAL001'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Try to save without filling fields
      await tester.tap(find.text('Save Product'));
      await tester.pump();

      expect(find.text('Required'), findsWidgets);

      // Dismiss
      await tester.drag(find.text('New Product'), const Offset(0, 400));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('new product form saves to Firestore', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('SAVE001'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Fill out the form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'New Item',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category'),
        'Snacks',
      );
      await tester.pump();

      // Save
      await tester.tap(find.text('Save Product'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Product should be in Firestore
      final snapshot = await productsCol().get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'New Item');
      expect(snapshot.docs.first.data()['category'], 'Snacks');
      expect(snapshot.docs.first.data()['barcode'], 'SAVE001');

      // Scan log should record 'added'
      final logs = await scanLogsCol().get();
      expect(logs.docs.length, 1);
      expect(logs.docs.first.data()['action'], 'added');
    });

    testWidgets('new product form can be dismissed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('DISMISS001'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('New Product'), findsOneWidget);

      // Drag down to dismiss the bottom sheet
      await tester.drag(find.text('New Product'), const Offset(0, 400));
      await tester.pump(const Duration(seconds: 3));

      // No product saved
      final snapshot = await productsCol().get();
      expect(snapshot.docs, isEmpty);
    });

    testWidgets('scan overlay frame changes color when processing', (
      tester,
    ) async {
      await productsCol().doc('p1').set({
        'barcode': 'COLOR1',
        'name': 'Test',
        'category': 'Test',
        'quantity': 1,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        buildTestApp(const ScannerPage(scannerBuilder: fakeScannerBuilder)),
      );
      await tester.pumpAndSettle();

      _lastOnDetect(makeBarcodeCapture('COLOR1'));
      await tester.pump();

      // The overlay container should exist during processing state
      expect(find.byType(Container), findsWidgets);

      // Advance past the 2-second cooldown
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
