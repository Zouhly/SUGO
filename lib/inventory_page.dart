/// Inventory dashboard – wabi-sabi earth-inspired design.
///
/// Features a stock-overview chart, category-coloured product cards with
/// organic shapes, search, and quick quantity controls.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SUGO',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SugoColors.bark,
          ),
        ),
      ),
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

          if (allProducts.isEmpty) {
            return _EmptyState();
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

/// Empty state with earthy illustration.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: SugoColors.mossPale,
              borderRadius: SugoBorders.card,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 48,
              color: SugoColors.moss,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No products yet',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SugoColors.bark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a barcode to add your first item.',
            style: GoogleFonts.lora(fontSize: 14, color: SugoColors.warmGrey),
          ),
        ],
      ),
    );
  }
}

/// Search bar with earthy styling.
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
        style: GoogleFonts.lora(fontSize: 14, color: SugoColors.bark),
        decoration: InputDecoration(
          hintText: 'Search products…',
          prefixIcon: const Icon(Icons.search, color: SugoColors.warmGrey),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Three dashboard stat cards with grain-textured backgrounds.
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
              icon: Icons.inventory_2_outlined,
              color: SugoColors.moss,
              bgColor: SugoColors.mossPale,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Low stock',
              value: '$lowStock',
              icon: Icons.warning_amber_rounded,
              color: SugoColors.statusWarning,
              bgColor: const Color(0xFFF5EDD0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Out of stock',
              value: '$outOfStock',
              icon: Icons.error_outline_rounded,
              color: SugoColors.statusDanger,
              bgColor: SugoColors.terracottaPale,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual stat card with organic shape and grain overlay.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SugoBorders.card,
        boxShadow: SugoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SugoColors.warmGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut chart showing stock distribution by category.
class _StockChart extends StatelessWidget {
  final List<Product> products;
  const _StockChart({required this.products});

  @override
  Widget build(BuildContext context) {
    // Group quantities by category.
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
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SugoColors.bark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // Donut chart
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
                // Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.take(6).map((e) {
                      final style = categoryStyleFor(e.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
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
                                style: GoogleFonts.lora(
                                  fontSize: 12,
                                  color: SugoColors.bark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: GoogleFonts.lora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: SugoColors.warmGrey,
                              ),
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

/// Horizontal scrolling category filter chips with icons.
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
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.grid_view_rounded, size: 16),
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              selectedColor: SugoColors.mossPale,
            ),
          ),
          ...categories.map((cat) {
            final style = categoryStyleFor(cat);
            final isSelected = selected == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  style.icon,
                  size: 16,
                  color: isSelected ? style.color : SugoColors.warmGrey,
                ),
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : cat),
                selectedColor: style.color.withAlpha(35),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Product card with organic shape, category colour accent, and controls.
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
    final catStyle = categoryStyleFor(product.category);
    final dateFormat = DateFormat('MMM d, yyyy – HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SugoBorders.card,
        boxShadow: SugoShadows.soft,
        border: Border(
          left: BorderSide(
            color: isOutOfStock
                ? SugoColors.statusDanger
                : isLowStock
                ? SugoColors.statusWarning
                : catStyle.color,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Category icon ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catStyle.color.withAlpha(25),
                borderRadius: SugoBorders.chip,
              ),
              child: Icon(catStyle.icon, color: catStyle.color, size: 22),
            ),
            const SizedBox(width: 12),

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
                          style: GoogleFonts.lora(
                            fontSize: 15,
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
                  const SizedBox(height: 3),
                  Text(
                    product.category,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: catStyle.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${dateFormat.format(product.updatedAt)}',
                    style: GoogleFonts.lora(
                      fontSize: 10,
                      color: SugoColors.warmGrey,
                    ),
                  ),
                ],
              ),
            ),

            // ── Quantity controls ──
            Column(
              children: [
                Text(
                  '${product.quantity}',
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isOutOfStock
                        ? SugoColors.statusDanger
                        : isLowStock
                        ? SugoColors.statusWarning
                        : SugoColors.moss,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleBtn(
                      icon: Icons.remove,
                      onPressed: onDecrement,
                      color: SugoColors.terracotta,
                    ),
                    const SizedBox(width: 6),
                    _CircleBtn(
                      icon: Icons.add,
                      onPressed: onIncrement,
                      color: SugoColors.moss,
                    ),
                  ],
                ),
              ],
            ),

            // ── Actions ──
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: SugoColors.warmGrey,
                size: 20,
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

/// Status badge with organic shape.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: SugoBorders.chip,
      ),
      child: Text(
        label,
        style: GoogleFonts.lora(
          color: color,
          fontSize: 10,
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
          color: color.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
