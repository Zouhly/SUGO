/// Data models for the Food Inventory app.
///
/// Contains [Product] for inventory items and [ScanLog] for scan history.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product in the inventory.
class Product {
  /// Firestore document ID (same as the barcode).
  final String id;

  /// The barcode / QR code string.
  final String barcode;

  /// Human-readable product name.
  final String name;

  /// Category for grouping (e.g. "Dairy", "Snacks").
  final String category;

  /// Current quantity in stock.
  final int quantity;

  /// Minimum threshold – if quantity <= this, the item is flagged.
  final int minThreshold;

  /// When the product was first added.
  final DateTime createdAt;

  /// Last time the product was scanned / updated.
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.minThreshold = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Build a [Product] from a Firestore document snapshot.
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      barcode: data['barcode'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      quantity: data['quantity'] ?? 0,
      minThreshold: data['minThreshold'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert this product to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'barcode': barcode,
      'name': name,
      'category': category,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields.
  Product copyWith({
    String? name,
    String? category,
    int? quantity,
    int? minThreshold,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      barcode: barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a single scan event for audit / history purposes.
class ScanLog {
  /// Firestore document ID (auto-generated).
  final String? id;

  /// The barcode that was scanned.
  final String barcode;

  /// Product name at the time of scan.
  final String productName;

  /// What happened: "added", "incremented", etc.
  final String action;

  /// When the scan occurred.
  final DateTime scannedAt;

  ScanLog({
    this.id,
    required this.barcode,
    required this.productName,
    required this.action,
    required this.scannedAt,
  });

  /// Build a [ScanLog] from a Firestore document.
  factory ScanLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScanLog(
      id: doc.id,
      barcode: data['barcode'] ?? '',
      productName: data['productName'] ?? '',
      action: data['action'] ?? '',
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'barcode': barcode,
      'productName': productName,
      'action': action,
      'scannedAt': Timestamp.fromDate(scannedAt),
    };
  }
}
