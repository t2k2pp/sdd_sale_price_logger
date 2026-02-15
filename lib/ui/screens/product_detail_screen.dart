import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/upsert_product_dialog.dart';
import 'price_history_screen.dart';
import 'add_entry_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Product _product;
  final _calcQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  @override
  void dispose() {
    _calcQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await showUpsertProductDialog(
                context,
                database,
                existingProduct: _product,
              );
              if (updated != null && mounted) {
                setState(() {
                  _product = updated;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final priceCount =
                  await (database.select(database.prices)
                        ..where((t) => t.productId.equals(_product.id)))
                      .get()
                      .then((l) => l.length);

              if (!context.mounted) return;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Product?'),
                  content: Text(
                    'Deleting this product will also delete $priceCount price records.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () async {
                        await database.transaction(() async {
                          await (database.delete(database.prices)
                                ..where((t) => t.productId.equals(_product.id)))
                              .go();
                          await (database.delete(
                            database.products,
                          )..where((t) => t.id.equals(_product.id))).go();
                        });
                        if (context.mounted) {
                          Navigator.pop(context); // dialog
                          Navigator.pop(context); // screen
                        }
                      },
                      child: Text(
                        l10n.deleteConfirm,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image/Emoji Header
            _buildProductHeader(context, colorScheme, l10n),
            const SizedBox(height: 16),

            // Latest Price Summary
            _buildLatestPriceSummary(context, database, l10n, colorScheme),
            const SizedBox(height: 16),

            // View History Button (F6)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PriceHistoryScreen(product: _product),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: Text(l10n.viewHistory),
              ),
            ),
            const SizedBox(height: 24),

            // Price Calculator (F7)
            if (_product.volume != null && _product.volumeUnit != null)
              _buildPriceCalculator(context, database, l10n, colorScheme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEntryScreen(initialProduct: _product),
            ),
          );
        },
        tooltip: l10n.addPrice,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image/Emoji (F5 - tap to enlarge)
            GestureDetector(
              onTap: _product.imagePath != null
                  ? () => _showFullImage(context)
                  : null,
              child: _buildProductAvatar(colorScheme),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_product.volume != null &&
                      _product.volumeUnit != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.volumeLabel(
                          _product.volume! % 1 == 0
                              ? _product.volume!.toInt().toString()
                              : _product.volume.toString(),
                          _product.volumeUnit!,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAvatar(ColorScheme colorScheme) {
    if (_product.imagePath != null) {
      return Hero(
        tag: 'product_image_${_product.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_product.imagePath!),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    } else if (_product.emoji != null) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: Text(_product.emoji!, style: const TextStyle(fontSize: 48)),
        ),
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: colorScheme.outline,
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: Hero(
                  tag: 'product_image_${_product.id}',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(_product.imagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildLatestPriceSummary(
    BuildContext context,
    AppDatabase database,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return StreamBuilder<List<drift.TypedResult>>(
      stream:
          (database.select(database.prices)
                ..where((t) => t.productId.equals(_product.id))
                ..orderBy([
                  (t) => drift.OrderingTerm(
                    expression: t.date,
                    mode: drift.OrderingMode.desc,
                  ),
                ])
                ..limit(3))
              .join([
                drift.innerJoin(
                  database.shops,
                  database.shops.id.equalsExp(database.prices.shopId),
                ),
              ])
              .watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noPriceHistory,
                  style: TextStyle(color: colorScheme.outline),
                ),
              ),
            ),
          );
        }

        final latest = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.latestPrice,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...latest.map((row) {
                  final price = row.readTable(database.prices);
                  final shop = row.readTable(database.shops);
                  final taxLabel = price.isTaxIncluded
                      ? l10n.taxIncludedLabel
                      : l10n.taxExcludedLabel;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${shop.name} - ${DateFormat.yMd().format(price.date)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '¥${price.price} ($taxLabel)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceCalculator(
    BuildContext context,
    AppDatabase database,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return StreamBuilder<List<Price>>(
      stream:
          (database.select(database.prices)
                ..where((t) => t.productId.equals(_product.id))
                ..orderBy([
                  (t) => drift.OrderingTerm(
                    expression: t.date,
                    mode: drift.OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final latestPrice = snapshot.data!.first;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.priceCalculator,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${l10n.price}: ¥${latestPrice.price}  /  '
                  '${l10n.volume}: ${_product.volume! % 1 == 0 ? _product.volume!.toInt() : _product.volume}${_product.volumeUnit}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _calcQuantityController,
                        decoration: InputDecoration(
                          labelText: l10n.inputQuantity,
                          suffixText: _product.volumeUnit,
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '→',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Builder(
                      builder: (context) {
                        final qty = double.tryParse(
                          _calcQuantityController.text,
                        );
                        if (qty == null || qty <= 0 || _product.volume == 0) {
                          return Text(
                            '--',
                            style: Theme.of(context).textTheme.headlineSmall,
                          );
                        }
                        final unitPrice = latestPrice.price / _product.volume!;
                        final calcPrice = unitPrice * qty;
                        return Text(
                          l10n.calculatedPrice(calcPrice.toStringAsFixed(1)),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
