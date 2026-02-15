import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/price_history_chart.dart';
import 'add_entry_screen.dart';

class PriceHistoryScreen extends ConsumerStatefulWidget {
  final Product product;

  const PriceHistoryScreen({super.key, required this.product});

  @override
  ConsumerState<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends ConsumerState<PriceHistoryScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.month;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.product.name} - ${l10n.history}')),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(12.0),
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
          Expanded(
            child: StreamBuilder<List<drift.TypedResult>>(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noPriceHistory),
                      ],
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
                    : '¥$bestPriceRaw (${l10n.taxExcludedLabel}) → ¥${minEffectivePrice.toStringAsFixed(0)} (${l10n.taxIncludedLabel})';

                return Column(
                  children: [
                    // Best Price Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Card(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.emoji_events,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            '${l10n.bestPrice} (${l10n.taxIncludedLabel})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$bestPriceDisplay ${l10n.at} $bestShop',
                          ),
                        ),
                      ),
                    ),
                    // Chart
                    SizedBox(
                      height: 250,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PriceHistoryChart(
                          prices: prices,
                          period: _selectedPeriod,
                        ),
                      ),
                    ),
                    const Divider(),
                    // History List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final row = results[index];
                          final price = row.readTable(database.prices);
                          final shop = row.readTable(database.shops);
                          final taxLabel = price.isTaxIncluded
                              ? l10n.taxIncludedLabel
                              : l10n.taxExcludedLabel;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.secondaryContainer,
                                child: Icon(
                                  Icons.receipt,
                                  size: 18,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                              title: Text(
                                '¥${price.price} ($taxLabel)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${shop.name} - ${DateFormat.yMMMd().format(price.date)}',
                              ),
                              onLongPress: () {
                                _showPriceActions(
                                  context,
                                  database,
                                  price,
                                  l10n,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPriceActions(
    BuildContext context,
    AppDatabase database,
    Price price,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Price'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEntryScreen(
                        initialProduct: widget.product,
                        entryToEdit: price,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  l10n.deleteConfirm,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Price?'),
                      content: const Text(
                        'Are you sure you want to delete this price record?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () async {
                            await database.prices.deleteWhere(
                              (t) => t.id.equals(price.id),
                            );
                            if (context.mounted) Navigator.pop(context);
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
        );
      },
    );
  }
}
