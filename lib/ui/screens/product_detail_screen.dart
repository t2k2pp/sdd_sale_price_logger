import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../widgets/price_history_chart.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                      ])
                      .watch(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data!;
                final prices = results
                    .map((row) => row.readTable(database.prices))
                    .toList();

                if (prices.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No price history yet.'),
                    ),
                  );
                }

                // Best Price Calculation
                int minPrice = prices.first.price;
                String bestShop = '';
                // Need to find the shop name for the min price
                // We can iterate results
                for (var row in results) {
                  final p = row.readTable(database.prices);
                  if (p.price <= minPrice) {
                    minPrice = p.price;
                    bestShop = row.readTable(database.shops).name;
                  }
                }

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
                          title: const Text('Best Price'),
                          subtitle: Text('¥$minPrice at $bestShop'),
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
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'History',
                        style: TextStyle(
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

                        return ListTile(
                          title: Text('¥${price.price}'),
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
    );
  }
}
