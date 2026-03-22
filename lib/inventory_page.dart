/// Inventory dashboard – lists all products with real-time updates.
///
/// Products with quantity == 0 or below their minimum threshold are
/// highlighted so you can restock at a glance.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'models.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirestoreService _firestoreService = FirestoreService.instance;

  /// Current search / filter query.
  String _searchQuery = '';

  /// Selected category filter (null = show all).
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _firestoreService.streamProducts(),
        builder: (context, snapshot) {
          // ── Loading state ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error state ──
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allProducts = snapshot.data ?? [];

          // ── Collect unique categories for the filter chips ──
          final categories = allProducts.map((p) => p.category).toSet().toList()
            ..sort();

          // ── Apply filters ──
          final products = allProducts.where((p) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                p.name.toLowerCase().contains(_searchQuery) ||
                p.barcode.toLowerCase().contains(_searchQuery) ||
                p.category.toLowerCase().contains(_searchQuery);
            final matchesCategory =
                _categoryFilter == null || p.category == _categoryFilter;
            return matchesSearch && matchesCategory;
          }).toList();

          // ── Empty state ──
          if (allProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Scan a barcode to add your first item.'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Category filter chips ──
              if (categories.length > 1)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _categoryFilter == null,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = null),
                        ),
                      ),
                      ...categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: _categoryFilter == cat,
                            onSelected: (_) => setState(
                              () => _categoryFilter = _categoryFilter == cat
                                  ? null
                                  : cat,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // ── Summary bar ──
              _SummaryBar(products: allProducts),

              // ── Product list ──
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('No matching products.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return _ProductTile(
                            product: products[index],
                            onIncrement: () => _firestoreService
                                .incrementQuantity(products[index].id),
                            onDecrement: () => _firestoreService
                                .decrementQuantity(products[index].id),
                            onDelete: () => _confirmDelete(products[index]),
                            onEdit: () => _showEditDialog(products[index]),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Delete confirmation ──
  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Remove "${product.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteProduct(product.id);
    }
  }

  // ── Edit dialog ──
  Future<void> _showEditDialog(Product product) async {
    final nameCtrl = TextEditingController(text: product.name);
    final categoryCtrl = TextEditingController(text: product.category);
    final quantityCtrl = TextEditingController(
      text: product.quantity.toString(),
    );
    final thresholdCtrl = TextEditingController(
      text: product.minThreshold.toString(),
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Product'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: thresholdCtrl,
                  decoration: const InputDecoration(labelText: 'Min threshold'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await _firestoreService.updateProduct(
        product.id,
        name: nameCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        quantity: int.tryParse(quantityCtrl.text) ?? product.quantity,
        minThreshold: int.tryParse(thresholdCtrl.text) ?? product.minThreshold,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Compact summary bar showing total products and low-stock count.
class _SummaryBar extends StatelessWidget {
  final List<Product> products;
  const _SummaryBar({required this.products});

  @override
  Widget build(BuildContext context) {
    final lowStock = products.where((p) => p.quantity <= p.minThreshold).length;
    final outOfStock = products.where((p) => p.quantity == 0).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            label: 'Total',
            value: '${products.length}',
            color: Theme.of(context).colorScheme.primary,
          ),
          _StatChip(
            label: 'Low stock',
            value: '$lowStock',
            color: Colors.orange,
          ),
          _StatChip(
            label: 'Out of stock',
            value: '$outOfStock',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

/// Small stat indicator used in the summary bar.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// A single product row with quantity controls.
class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ProductTile({
    required this.product,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Determine highlight color based on stock level.
    final isOutOfStock = product.quantity == 0;
    final isLowStock =
        !isOutOfStock && product.quantity <= product.minThreshold;

    final Color tileColor;
    if (isOutOfStock) {
      tileColor = Colors.red.shade50;
    } else if (isLowStock) {
      tileColor = Colors.orange.shade50;
    } else {
      tileColor = Colors.transparent;
    }

    final dateFormat = DateFormat('MMM d, yyyy – HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: tileColor,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Left: product info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name + badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOutOfStock) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'OUT', color: Colors.red),
                      ] else if (isLowStock) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'LOW', color: Colors.orange),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${dateFormat.format(product.updatedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // ── Right: quantity controls ──
            Column(
              children: [
                // Quantity display
                Text(
                  '${product.quantity}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock
                        ? Colors.red
                        : isLowStock
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),

                // +/- buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleBtn(
                      icon: Icons.remove,
                      onPressed: onDecrement,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(width: 8),
                    _CircleBtn(
                      icon: Icons.add,
                      onPressed: onIncrement,
                      color: Colors.green.shade400,
                    ),
                  ],
                ),
              ],
            ),

            // ── Actions menu ──
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small colored badge (e.g. "OUT", "LOW").
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Tiny circular icon button for +/- quantity controls.
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  const _CircleBtn({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
