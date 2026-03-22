/// Scanner page – uses the phone camera to scan barcodes / QR codes.
///
/// After a successful scan the page checks Firestore:
///   • Product exists → increment quantity & log.
///   • Product is new  → show a form to create it.
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'firestore_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  /// Controller for the camera scanner.
  final MobileScannerController _scannerController = MobileScannerController();

  /// Firestore helper.
  final FirestoreService _firestoreService = FirestoreService.instance;

  /// Prevents processing the same barcode multiple times in a row.
  bool _isProcessing = false;

  /// Last scanned barcode (shown in the UI).
  String? _lastScanned;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ── Scan handler ──────────────────────────────────────────────────
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // Ignore if we are already processing a scan.
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = barcode;
    });

    try {
      // Check if the product already exists.
      final existing = await _firestoreService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (existing != null) {
        // ── Existing product → increment quantity ──
        await _firestoreService.incrementQuantity(existing.id);
        await _firestoreService.logScan(
          barcode: barcode,
          productName: existing.name,
          action: 'incremented',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${existing.name} — quantity +1 (now ${existing.quantity + 1})',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        // ── New product → show creation form ──
        await _showNewProductForm(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Small cooldown so the same code isn't scanned instantly again.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── New-product bottom sheet ──────────────────────────────────────
  Future<void> _showNewProductForm(String barcode) async {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final thresholdCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          // Push the sheet above the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Handle ──
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'New Product',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barcode: $barcode',
                      style: Theme.of(
                        ctx,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // ── Product name ──
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                        prefixIcon: Icon(Icons.fastfood_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Category ──
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Quantity & threshold side by side ──
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: quantityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: thresholdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Min threshold',
                              prefixIcon: Icon(Icons.warning_amber),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.of(ctx).pop(true);
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // If the user confirmed, save to Firestore.
    if (result == true) {
      final product = await _firestoreService.addProduct(
        barcode: barcode,
        name: nameCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        quantity: int.tryParse(quantityCtrl.text) ?? 1,
        minThreshold: int.tryParse(thresholdCtrl.text) ?? 1,
      );
      await _firestoreService.logScan(
        barcode: barcode,
        productName: product.name,
        action: 'added',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to inventory!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product')),
      body: Stack(
        children: [
          // ── Camera preview ──
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),

          // ── Overlay with scan frame ──
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.orange : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // ── Processing indicator ──
          if (_isProcessing)
            const Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),

          // ── Last scanned barcode label ──
          if (_lastScanned != null)
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Last scan: $_lastScanned',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
