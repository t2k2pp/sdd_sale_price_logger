import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../widgets/price_history_chart.dart';
import 'add_entry_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.month;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: widget.product.imagePath != null
                    ? Image.file(
                        File(widget.product.imagePath!),
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 100),
                      )
                    : Text(
                        widget.product.emoji ?? '📦',
                        style: const TextStyle(fontSize: 80),
                      ),
              ),
            ),
            // Period Selector
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SegmentedButton<ChartPeriod>(
                segments: const [
                  ButtonSegment(value: ChartPeriod.week, label: Text('1W')),
                  ButtonSegment(value: ChartPeriod.month, label: Text('1M')),
                  ButtonSegment(
                    value: ChartPeriod.threeMonths,
                    label: Text('3M'),
                  ),
                  ButtonSegment(value: ChartPeriod.year, label: Text('1Y')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                  });
                },
              ),
            ),

            // Chart & List
            StreamBuilder<List<drift.TypedResult>>(
              stream:
                  (database.select(database.prices)
                        ..where((t) => t.productId.equals(widget.product.id))
                        ..orderBy([
                          (t) => drift.OrderingTerm(
                            expression: t.date,
                            mode: drift.OrderingMode.desc,
                          ),
                        ]))
                      .join([
                        drift.innerJoin(
                          database.shops,
                          database.shops.id.equalsExp(database.prices.shopId),
                        ),
                        drift.innerJoin(
                          database.products,
                          database.products.id.equalsExp(
                            database.prices.productId,
                          ),
                        ),
                        drift.innerJoin(
                          database.categories,
                          database.categories.id.equalsExp(
                            database.products.categoryId,
                          ),
                        ),
                      ])
                      .watch(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(l10n.error(snapshot.error.toString())),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data!;
                final prices = results
                    .map((row) => row.readTable(database.prices))
                    .toList();

                if (prices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(l10n.noPriceHistory),
                    ),
                  );
                }

                // Best Price Calculation
                double minEffectivePrice = double.infinity;
                String bestShop = '';
                int bestPriceRaw = 0;
                bool bestIsTaxIncluded = true;

                for (var row in results) {
                  final p = row.readTable(database.prices);
                  final c = row.readTable(database.categories);
                  final shopName = row.readTable(database.shops).name;

                  double effectivePrice;
                  if (p.isTaxIncluded) {
                    effectivePrice = p.price.toDouble();
                  } else {
                    effectivePrice = p.price * (1 + c.taxRate / 100);
                  }

                  if (effectivePrice < minEffectivePrice) {
                    minEffectivePrice = effectivePrice;
                    bestShop = shopName;
                    bestPriceRaw = p.price;
                    bestIsTaxIncluded = p.isTaxIncluded;
                  }
                }

                final bestPriceDisplay = bestIsTaxIncluded
                    ? '¥$bestPriceRaw (${l10n.taxIncludedLabel})'
                    : '¥$bestPriceRaw (${l10n.taxExcludedLabel}) -> ¥${minEffectivePrice.toStringAsFixed(0)} (${l10n.taxIncludedLabel})';

                return Column(
                  children: [
                    // Best Price Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Colors.green.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.thumb_up,
                            color: Colors.green,
                          ),
                          title: Text(
                            '${l10n.bestPrice} (${l10n.taxIncludedLabel})',
                          ),
                          subtitle: Text('$bestPriceDisplay at $bestShop'),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 300,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PriceHistoryChart(
                          prices: prices,
                          period: _selectedPeriod,
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        l10n.history,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final row = results[index];
                        final price = row.readTable(database.prices);
                        final shop = row.readTable(database.shops);
                        final taxLabel = price.isTaxIncluded
                            ? l10n.taxIncludedLabel
                            : l10n.taxExcludedLabel;

                        return ListTile(
                          title: Text('¥${price.price} ($taxLabel)'),
                          subtitle: Text(
                            '${shop.name} - ${DateFormat.yMMMd().format(price.date)}',
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddEntryScreen(initialProduct: widget.product),
            ),
          );
        },
        tooltip: l10n.addPrice,
        child: const Icon(Icons.add),
      ),
    );
  }
}
