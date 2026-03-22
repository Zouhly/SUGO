import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_inventory/models.dart';

void main() {
  group('Product', () {
    final now = DateTime(2026, 3, 22, 10, 0);

    Product makeProduct({
      String id = 'doc1',
      String barcode = '123456',
      String name = 'Milk',
      String category = 'Dairy',
      int quantity = 5,
      int minThreshold = 2,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return Product(
        id: id,
        barcode: barcode,
        name: name,
        category: category,
        quantity: quantity,
        minThreshold: minThreshold,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('constructor sets all fields', () {
      final p = makeProduct();
      expect(p.id, 'doc1');
      expect(p.barcode, '123456');
      expect(p.name, 'Milk');
      expect(p.category, 'Dairy');
      expect(p.quantity, 5);
      expect(p.minThreshold, 2);
      expect(p.createdAt, now);
      expect(p.updatedAt, now);
    });

    test('constructor uses default quantity and minThreshold', () {
      final p = Product(
        id: 'x',
        barcode: 'b',
        name: 'n',
        category: 'c',
        createdAt: now,
        updatedAt: now,
      );
      expect(p.quantity, 1);
      expect(p.minThreshold, 1);
    });

    test('fromFirestore parses a document correctly', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('products').doc('abc').set({
        'barcode': '999',
        'name': 'Eggs',
        'category': 'Dairy',
        'quantity': 12,
        'minThreshold': 3,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final doc = await firestore.collection('products').doc('abc').get();
      final p = Product.fromFirestore(doc);

      expect(p.id, 'abc');
      expect(p.barcode, '999');
      expect(p.name, 'Eggs');
      expect(p.category, 'Dairy');
      expect(p.quantity, 12);
      expect(p.minThreshold, 3);
      expect(p.createdAt, now);
      expect(p.updatedAt, now);
    });

    test('fromFirestore handles missing fields with defaults', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('products').doc('empty').set({});

      final doc = await firestore.collection('products').doc('empty').get();
      final p = Product.fromFirestore(doc);

      expect(p.id, 'empty');
      expect(p.barcode, '');
      expect(p.name, '');
      expect(p.category, 'Uncategorized');
      expect(p.quantity, 0);
      expect(p.minThreshold, 1);
      // createdAt/updatedAt fallback to DateTime.now(), just check they exist
      expect(p.createdAt, isNotNull);
      expect(p.updatedAt, isNotNull);
    });

    test('toFirestore produces correct map', () {
      final p = makeProduct();
      final map = p.toFirestore();

      expect(map['barcode'], '123456');
      expect(map['name'], 'Milk');
      expect(map['category'], 'Dairy');
      expect(map['quantity'], 5);
      expect(map['minThreshold'], 2);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), now);
    });

    test('copyWith overrides specified fields only', () {
      final p = makeProduct();

      final updated = p.copyWith(name: 'Oat Milk', quantity: 10);
      expect(updated.name, 'Oat Milk');
      expect(updated.quantity, 10);
      // Unchanged fields
      expect(updated.id, 'doc1');
      expect(updated.barcode, '123456');
      expect(updated.category, 'Dairy');
      expect(updated.minThreshold, 2);
      expect(updated.createdAt, now);
    });

    test('copyWith with no arguments returns identical values', () {
      final p = makeProduct();
      final copy = p.copyWith();

      expect(copy.id, p.id);
      expect(copy.barcode, p.barcode);
      expect(copy.name, p.name);
      expect(copy.category, p.category);
      expect(copy.quantity, p.quantity);
      expect(copy.minThreshold, p.minThreshold);
      expect(copy.createdAt, p.createdAt);
      expect(copy.updatedAt, p.updatedAt);
    });

    test('copyWith can update all optional fields', () {
      final p = makeProduct();
      final later = DateTime(2026, 4, 1);
      final copy = p.copyWith(
        name: 'Cheese',
        category: 'Deli',
        quantity: 3,
        minThreshold: 1,
        updatedAt: later,
      );

      expect(copy.name, 'Cheese');
      expect(copy.category, 'Deli');
      expect(copy.quantity, 3);
      expect(copy.minThreshold, 1);
      expect(copy.updatedAt, later);
      // id, barcode, createdAt are unchanged
      expect(copy.id, p.id);
      expect(copy.barcode, p.barcode);
      expect(copy.createdAt, p.createdAt);
    });
  });

  group('ScanLog', () {
    final now = DateTime(2026, 3, 22, 12, 0);

    test('constructor sets all fields', () {
      final log = ScanLog(
        id: 'log1',
        barcode: '999',
        productName: 'Eggs',
        action: 'incremented',
        scannedAt: now,
      );

      expect(log.id, 'log1');
      expect(log.barcode, '999');
      expect(log.productName, 'Eggs');
      expect(log.action, 'incremented');
      expect(log.scannedAt, now);
    });

    test('id is optional', () {
      final log = ScanLog(
        barcode: '111',
        productName: 'Water',
        action: 'added',
        scannedAt: now,
      );
      expect(log.id, isNull);
    });

    test('fromFirestore parses a document correctly', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('scanLogs').doc('s1').set({
        'barcode': '555',
        'productName': 'Bread',
        'action': 'added',
        'scannedAt': Timestamp.fromDate(now),
      });

      final doc = await firestore.collection('scanLogs').doc('s1').get();
      final log = ScanLog.fromFirestore(doc);

      expect(log.id, 's1');
      expect(log.barcode, '555');
      expect(log.productName, 'Bread');
      expect(log.action, 'added');
      expect(log.scannedAt, now);
    });

    test('fromFirestore handles missing fields with defaults', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('scanLogs').doc('empty').set({});

      final doc = await firestore.collection('scanLogs').doc('empty').get();
      final log = ScanLog.fromFirestore(doc);

      expect(log.id, 'empty');
      expect(log.barcode, '');
      expect(log.productName, '');
      expect(log.action, '');
      expect(log.scannedAt, isNotNull);
    });

    test('toFirestore produces correct map', () {
      final log = ScanLog(
        barcode: '777',
        productName: 'Rice',
        action: 'incremented',
        scannedAt: now,
      );
      final map = log.toFirestore();

      expect(map['barcode'], '777');
      expect(map['productName'], 'Rice');
      expect(map['action'], 'incremented');
      expect(map['scannedAt'], isA<Timestamp>());
      expect((map['scannedAt'] as Timestamp).toDate(), now);
    });
  });
}
