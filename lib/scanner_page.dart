/// Scanner page – wabi-sabi earth-styled barcode scanner.
///
/// After a successful scan the page checks Firestore:
///   • Product exists → increment quantity & log.
///   • Product is new  → show a form to create it.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'firestore_service.dart';
import 'theme.dart';

/// Signature for a builder that returns the camera scanner widget.
typedef ScannerWidgetBuilder =
    Widget Function(
      MobileScannerController controller,
      void Function(BarcodeCapture) onDetect,
    );

class ScannerPage extends StatefulWidget {
  /// Optional builder to override the scanner widget (used in tests).
  final ScannerWidgetBuilder? scannerBuilder;

  const ScannerPage({super.key, this.scannerBuilder});

  @override
  State<ScannerPage> createState() => ScannerPageState();
}

class ScannerPageState extends State<ScannerPage> {
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
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = barcode;
    });

    try {
      final existing = await _firestoreService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (existing != null) {
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
              backgroundColor: SugoColors.moss,
            ),
          );
        }
      } else {
        await _showNewProductForm(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: SugoColors.statusDanger,
          ),
        );
      }
    } finally {
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: SugoColors.parchment,
              borderRadius: SugoBorders.sheet,
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
                        color: SugoColors.sandDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'New Product',
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SugoColors.bark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barcode: $barcode',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        color: SugoColors.warmGrey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Product name ──
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                        prefixIcon: Icon(Icons.eco_outlined),
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
            backgroundColor: SugoColors.moss,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Product',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SugoColors.bark,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Camera preview ──
          widget.scannerBuilder != null
              ? widget.scannerBuilder!(_scannerController, _onBarcodeDetected)
              : MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                ),

          // ── Organic scan frame overlay ──
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing
                      ? SugoColors.terracotta
                      : SugoColors.sand.withAlpha(200),
                  width: 3,
                ),
                borderRadius: SugoBorders.card,
              ),
            ),
          ),

          // ── Processing indicator ──
          if (_isProcessing)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: SugoColors.terracotta),
              ),
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
                  color: SugoColors.bark.withAlpha(180),
                  borderRadius: SugoBorders.chip,
                ),
                child: Text(
                  'Last scan: $_lastScanned',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    color: SugoColors.sand,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
