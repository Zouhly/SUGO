import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_inventory/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  const testUid = 'test-uid';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService.instance;
    service.setFirestoreInstance(fakeFirestore);
    service.setUid(testUid);
  });

  /// Helper to get the user-scoped products collection.
  CollectionReference<Map<String, dynamic>> productsCol() =>
      fakeFirestore.collection('users').doc(testUid).collection('products');

  /// Helper to get the user-scoped scanLogs collection.
  CollectionReference<Map<String, dynamic>> scanLogsCol() =>
      fakeFirestore.collection('users').doc(testUid).collection('scanLogs');

  group('streamProducts', () {
    test('emits empty list when no products exist', () async {
      final products = await service.streamProducts().first;
      expect(products, isEmpty);
    });

    test('emits products ordered by name', () async {
      await productsCol().add({
        'barcode': '2',
        'name': 'Banana',
        'category': 'Fruit',
        'quantity': 3,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await productsCol().add({
        'barcode': '1',
        'name': 'Apple',
        'category': 'Fruit',
        'quantity': 5,
        'minThreshold': 2,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final products = await service.streamProducts().first;
      expect(products.length, 2);
      expect(products[0].name, 'Apple');
      expect(products[1].name, 'Banana');
    });
  });

  group('getProductByBarcode', () {
    test('returns null when barcode not found', () async {
      final result = await service.getProductByBarcode('nonexistent');
      expect(result, isNull);
    });

    test('returns product matching the barcode', () async {
      await productsCol().add({
        'barcode': 'ABC123',
        'name': 'Milk',
        'category': 'Dairy',
        'quantity': 2,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final result = await service.getProductByBarcode('ABC123');
      expect(result, isNotNull);
      expect(result!.name, 'Milk');
      expect(result.barcode, 'ABC123');
    });
  });

  group('addProduct', () {
    test('creates a new product and returns it with an ID', () async {
      final product = await service.addProduct(
        barcode: 'NEW001',
        name: 'Cheese',
        category: 'Dairy',
        quantity: 3,
        minThreshold: 1,
      );

      expect(product.id, isNotEmpty);
      expect(product.barcode, 'NEW001');
      expect(product.name, 'Cheese');
      expect(product.category, 'Dairy');
      expect(product.quantity, 3);
      expect(product.minThreshold, 1);

      // Verify it's in Firestore
      final stored = await service.getProductByBarcode('NEW001');
      expect(stored, isNotNull);
      expect(stored!.name, 'Cheese');
    });

    test('uses default quantity and minThreshold', () async {
      final product = await service.addProduct(
        barcode: 'DEF001',
        name: 'Water',
        category: 'Drinks',
      );

      expect(product.quantity, 1);
      expect(product.minThreshold, 1);
    });
  });

  group('incrementQuantity', () {
    test('increases quantity by 1 by default', () async {
      final docRef = await productsCol().add({
        'barcode': 'INC1',
        'name': 'Juice',
        'category': 'Drinks',
        'quantity': 5,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.incrementQuantity(docRef.id);

      final doc = await productsCol().doc(docRef.id).get();
      expect((doc.data()!)['quantity'], 6);
    });

    test('increases quantity by custom amount', () async {
      final docRef = await productsCol().add({
        'barcode': 'INC2',
        'name': 'Rice',
        'category': 'Grains',
        'quantity': 10,
        'minThreshold': 2,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.incrementQuantity(docRef.id, amount: 5);

      final doc = await productsCol().doc(docRef.id).get();
      expect((doc.data()!)['quantity'], 15);
    });
  });

  group('decrementQuantity', () {
    test('decreases quantity by 1', () async {
      final docRef = await productsCol().add({
        'barcode': 'DEC1',
        'name': 'Bread',
        'category': 'Bakery',
        'quantity': 3,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.decrementQuantity(docRef.id);

      final doc = await productsCol().doc(docRef.id).get();
      expect((doc.data()!)['quantity'], 2);
    });

    test('does not go below zero', () async {
      final docRef = await productsCol().add({
        'barcode': 'DEC2',
        'name': 'Butter',
        'category': 'Dairy',
        'quantity': 0,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.decrementQuantity(docRef.id);

      final doc = await productsCol().doc(docRef.id).get();
      expect((doc.data()!)['quantity'], 0);
    });

    test('decreases by custom amount clamped to 0', () async {
      final docRef = await productsCol().add({
        'barcode': 'DEC3',
        'name': 'Eggs',
        'category': 'Dairy',
        'quantity': 2,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.decrementQuantity(docRef.id, amount: 5);

      final doc = await productsCol().doc(docRef.id).get();
      expect((doc.data()!)['quantity'], 0);
    });
  });

  group('updateProduct', () {
    test('updates only specified fields', () async {
      final docRef = await productsCol().add({
        'barcode': 'UPD1',
        'name': 'Old Name',
        'category': 'Old Cat',
        'quantity': 5,
        'minThreshold': 2,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.updateProduct(docRef.id, name: 'New Name');

      final doc = await productsCol().doc(docRef.id).get();
      expect((doc.data()!)['name'], 'New Name');
      expect((doc.data()!)['category'], 'Old Cat'); // unchanged
    });

    test('can update all editable fields', () async {
      final docRef = await productsCol().add({
        'barcode': 'UPD2',
        'name': 'Old',
        'category': 'Old',
        'quantity': 1,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.updateProduct(
        docRef.id,
        name: 'Updated',
        category: 'New Cat',
        quantity: 10,
        minThreshold: 3,
      );

      final doc = await productsCol().doc(docRef.id).get();
      final data = doc.data()!;
      expect(data['name'], 'Updated');
      expect(data['category'], 'New Cat');
      expect(data['quantity'], 10);
      expect(data['minThreshold'], 3);
      expect(data['updatedAt'], isNotNull);
    });
  });

  group('deleteProduct', () {
    test('removes the product document', () async {
      final docRef = await productsCol().add({
        'barcode': 'DEL1',
        'name': 'To Delete',
        'category': 'Test',
        'quantity': 1,
        'minThreshold': 1,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await service.deleteProduct(docRef.id);

      final doc = await productsCol().doc(docRef.id).get();
      expect(doc.exists, isFalse);
    });
  });

  group('logScan', () {
    test('creates a scan log document', () async {
      await service.logScan(
        barcode: 'LOG1',
        productName: 'Milk',
        action: 'incremented',
      );

      final snapshot = await scanLogsCol().get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['barcode'], 'LOG1');
      expect(data['productName'], 'Milk');
      expect(data['action'], 'incremented');
      expect(data['scannedAt'], isNotNull);
    });
  });

  group('streamRecentScans', () {
    test('emits empty list when no scans exist', () async {
      final scans = await service.streamRecentScans().first;
      expect(scans, isEmpty);
    });

    test('emits scan logs ordered by scannedAt descending', () async {
      final earlier = DateTime(2026, 1, 1);
      final later = DateTime(2026, 3, 1);

      await scanLogsCol().add({
        'barcode': '1',
        'productName': 'First',
        'action': 'added',
        'scannedAt': Timestamp.fromDate(earlier),
      });
      await scanLogsCol().add({
        'barcode': '2',
        'productName': 'Second',
        'action': 'added',
        'scannedAt': Timestamp.fromDate(later),
      });

      final scans = await service.streamRecentScans().first;
      expect(scans.length, 2);
      expect(scans[0].productName, 'Second');
      expect(scans[1].productName, 'First');
    });
  });
}
