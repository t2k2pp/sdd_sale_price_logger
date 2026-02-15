import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/upsert_shop_dialog.dart';
import 'shop_detail_screen.dart';

class ShopListScreen extends ConsumerWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Shop>>(
      stream: database.select(database.shops).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(l10n.error(snapshot.error.toString())));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final shops = snapshot.data!;

        if (shops.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noShopsFound,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await showUpsertShopDialog(context, database);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addShop),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: shops.length + 1,
          itemBuilder: (context, index) {
            if (index == shops.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await showUpsertShopDialog(context, database);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addShop),
                ),
              );
            }
            final shop = shops[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.store,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  shop.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: shop.memo != null && shop.memo!.isNotEmpty
                    ? Text(
                        shop.memo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ShopDetailScreen(shop: shop),
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
