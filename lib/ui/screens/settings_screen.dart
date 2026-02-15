import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';
import '../dialogs/upsert_product_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoryManagement)),
      body: const _CategoryList(),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return StreamBuilder<List<Category>>(
      stream: database.select(database.categories).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            final l10n = AppLocalizations.of(context)!;
            if (index == categories.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await showUpsertCategoryDialog(context, database);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addCategory),
                ),
              );
            }
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.category,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${l10n.taxRate}: ${category.taxRate}%'),
                onTap: () async {
                  await showUpsertCategoryDialog(
                    context,
                    database,
                    existingCategory: category,
                  );
                },
                onLongPress: () async {
                  final productsCount =
                      await (database.select(database.products)
                            ..where((t) => t.categoryId.equals(category.id)))
                          .get()
                          .then((l) => l.length);
                  final priceCountQuery = database.select(database.prices).join(
                    [
                      drift.innerJoin(
                        database.products,
                        database.products.id.equalsExp(
                          database.prices.productId,
                        ),
                      ),
                    ],
                  )..where(database.products.categoryId.equals(category.id));
                  final priceCount = await priceCountQuery.get().then(
                    (l) => l.length,
                  );

                  if (!context.mounted) return;

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Category?'),
                      content: Text(
                        'Deleting this category will delete $productsCount products and $priceCount price records.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () async {
                            await database.transaction(() async {
                              final products =
                                  await (database.select(database.products)
                                        ..where(
                                          (t) =>
                                              t.categoryId.equals(category.id),
                                        ))
                                      .get();
                              final productIds = products
                                  .map((p) => p.id)
                                  .toList();

                              if (productIds.isNotEmpty) {
                                await (database.delete(database.prices)..where(
                                      (t) => t.productId.isIn(productIds),
                                    ))
                                    .go();
                              }
                              await (database.delete(database.products)..where(
                                    (t) => t.categoryId.equals(category.id),
                                  ))
                                  .go();
                              await (database.delete(
                                database.categories,
                              )..where((t) => t.id.equals(category.id))).go();
                            });
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
            );
          },
        );
      },
    );
  }
}
