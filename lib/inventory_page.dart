/// Inventory dashboard – clean, minimal design.
///
/// Stock summary, category filters, search, and product list
/// with generous touch targets and readable text.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'models.dart';
import 'theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirestoreService _firestoreService = FirestoreService.instance;

  String _searchQuery = '';
  String? _categoryFilter;

  List<Product> _filterProducts(List<Product> allProducts) {
    return allProducts.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.barcode.toLowerCase().contains(_searchQuery) ||
          p.category.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _categoryFilter == null || p.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SUGO')),
      body: StreamBuilder<List<Product>>(
        stream: _firestoreService.streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: SugoColors.moss),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allProducts = snapshot.data ?? [];
          final categories = allProducts.map((p) => p.category).toSet().toList()
            ..sort();

          final products = _filterProducts(allProducts);

          if (allProducts.isEmpty) {
            return const _EmptyState();
          }

          return CustomScrollView(
            slivers: [
              // ── Search bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _SearchBar(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
              ),

              // ── Dashboard cards row ──
              SliverToBoxAdapter(child: _DashboardCards(products: allProducts)),

              // ── Stock overview chart ──
              if (categories.length > 1)
                SliverToBoxAdapter(child: _StockChart(products: allProducts)),

              // ── Category filter chips ──
              if (categories.length > 1)
                SliverToBoxAdapter(
                  child: _CategoryChips(
                    categories: categories,
                    selected: _categoryFilter,
                    onSelected: (cat) => setState(() => _categoryFilter = cat),
                  ),
                ),

              // ── Product list ──
              if (products.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No matching products.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProductCard(
                        product: products[index],
                        onIncrement: () => _firestoreService.incrementQuantity(
                          products[index].id,
                        ),
                        onDecrement: () => _firestoreService.decrementQuantity(
                          products[index].id,
                        ),
                        onDelete: () => _confirmDelete(products[index]),
                        onEdit: () => _showEditDialog(products[index]),
                      ),
                      childCount: products.length,
                    ),
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
            style: FilledButton.styleFrom(
              backgroundColor: SugoColors.statusDanger,
            ),
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

/// Empty state.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined, size: 56, color: SugoColors.warmGrey),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a barcode to add your first item.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SugoColors.warmGrey),
          ),
        ],
      ),
    );
  }
}

/// Search bar.
class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SugoBorders.chip,
        boxShadow: SugoShadows.soft,
      ),
      child: TextField(
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search products…',
          prefixIcon: const Icon(Icons.search, color: SugoColors.warmGrey),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Three dashboard stat cards.
class _DashboardCards extends StatelessWidget {
  final List<Product> products;
  const _DashboardCards({required this.products});

  @override
  Widget build(BuildContext context) {
    final total = products.length;
    final lowStock = products
        .where((p) => p.quantity > 0 && p.quantity <= p.minThreshold)
        .length;
    final outOfStock = products.where((p) => p.quantity == 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total',
              value: '$total',
              color: SugoColors.bark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Low stock',
              value: '$lowStock',
              color: SugoColors.statusWarning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Out of stock',
              value: '$outOfStock',
              color: SugoColors.statusDanger,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual stat card.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SugoBorders.card,
        boxShadow: SugoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Donut chart showing stock by category.
class _StockChart extends StatelessWidget {
  final List<Product> products;
  const _StockChart({required this.products});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> categoryQty = {};
    for (final p in products) {
      categoryQty[p.category] = (categoryQty[p.category] ?? 0) + p.quantity;
    }
    final entries = categoryQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SugoBorders.card,
        boxShadow: SugoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock by Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: entries.map((e) {
                        final style = categoryStyleFor(e.key);
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: style.color,
                          radius: 32,
                          title: '',
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.take(6).map((e) {
                      final style = categoryStyleFor(e.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: style.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrolling category filter chips.
class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map((cat) {
            final isSelected = selected == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : cat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Product card with clean layout and large touch targets.
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ProductCard({
    required this.product,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.quantity == 0;
    final isLowStock =
        !isOutOfStock && product.quantity <= product.minThreshold;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SugoBorders.card,
        boxShadow: SugoShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Product info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: SugoColors.bark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOutOfStock) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'OUT', color: SugoColors.statusDanger),
                      ] else if (isLowStock) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'LOW', color: SugoColors.statusWarning),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(fontSize: 14, color: SugoColors.warmGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(product.updatedAt),
                    style: TextStyle(fontSize: 13, color: SugoColors.warmGrey),
                  ),
                ],
              ),
            ),

            // ── Quantity controls ──
            Column(
              children: [
                Text(
                  '${product.quantity}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isOutOfStock
                        ? SugoColors.statusDanger
                        : isLowStock
                        ? SugoColors.statusWarning
                        : SugoColors.bark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleBtn(icon: Icons.remove, onPressed: onDecrement),
                    const SizedBox(width: 8),
                    _CircleBtn(icon: Icons.add, onPressed: onIncrement),
                  ],
                ),
              ],
            ),

            // ── Actions ──
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: SugoColors.warmGrey,
                size: 22,
              ),
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

/// Status badge.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: SugoBorders.chip,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Circular icon button for quantity controls.
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SugoColors.sand,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: SugoColors.bark),
      ),
    );
  }
}
