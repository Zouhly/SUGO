/// Firestore service layer.
///
/// Encapsulates all Firestore read / write operations so the UI
/// never talks to Firestore directly.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class FirestoreService {
  // ── Singleton ──────────────────────────────────────────────────────
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  /// Root Firestore instance.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to the "products" collection.
  CollectionReference get _productsRef => _db.collection('products');

  /// Reference to the "scanLogs" collection.
  CollectionReference get _scanLogsRef => _db.collection('scanLogs');

  // ── Products ───────────────────────────────────────────────────────

  /// Stream of all products ordered by name (real-time updates).
  Stream<List<Product>> streamProducts() {
    return _productsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  /// Fetch a single product by its barcode.
  /// Returns `null` if the barcode is not in the database.
  Future<Product?> getProductByBarcode(String barcode) async {
    final snapshot = await _productsRef
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Product.fromFirestore(snapshot.docs.first);
  }

  /// Add a brand-new product and return it.
  Future<Product> addProduct({
    required String barcode,
    required String name,
    required String category,
    int quantity = 1,
    int minThreshold = 1,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: '', // Firestore will assign the ID
      barcode: barcode,
      name: name,
      category: category,
      quantity: quantity,
      minThreshold: minThreshold,
      createdAt: now,
      updatedAt: now,
    );
    final docRef = await _productsRef.add(product.toFirestore());
    // Return the product with the real Firestore doc ID.
    return Product(
      id: docRef.id,
      barcode: barcode,
      name: name,
      category: category,
      quantity: quantity,
      minThreshold: minThreshold,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Increment the quantity of an existing product by [amount].
  Future<void> incrementQuantity(String docId, {int amount = 1}) async {
    await _productsRef.doc(docId).update({
      'quantity': FieldValue.increment(amount),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Decrement the quantity (will not go below 0).
  Future<void> decrementQuantity(String docId, {int amount = 1}) async {
    // Use a transaction to prevent going negative.
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(_productsRef.doc(docId));
      final current =
          (snapshot.data() as Map<String, dynamic>)['quantity'] as int;
      final newQty = (current - amount).clamp(0, current);
      tx.update(_productsRef.doc(docId), {
        'quantity': newQty,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Update editable fields of a product.
  Future<void> updateProduct(
    String docId, {
    String? name,
    String? category,
    int? quantity,
    int? minThreshold,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (name != null) updates['name'] = name;
    if (category != null) updates['category'] = category;
    if (quantity != null) updates['quantity'] = quantity;
    if (minThreshold != null) updates['minThreshold'] = minThreshold;
    await _productsRef.doc(docId).update(updates);
  }

  /// Delete a product by doc ID.
  Future<void> deleteProduct(String docId) async {
    await _productsRef.doc(docId).delete();
  }

  // ── Scan Logs ──────────────────────────────────────────────────────

  /// Log a scan event.
  Future<void> logScan({
    required String barcode,
    required String productName,
    required String action,
  }) async {
    final log = ScanLog(
      barcode: barcode,
      productName: productName,
      action: action,
      scannedAt: DateTime.now(),
    );
    await _scanLogsRef.add(log.toFirestore());
  }

  /// Stream recent scan logs (newest first, limited to last 50).
  Stream<List<ScanLog>> streamRecentScans() {
    return _scanLogsRef
        .orderBy('scannedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ScanLog.fromFirestore(doc))
              .toList();
        });
  }
}
