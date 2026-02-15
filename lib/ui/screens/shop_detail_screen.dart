import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/upsert_shop_dialog.dart';
import '../dialogs/upsert_shop_event_dialog.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  final Shop shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  late Shop _shop;

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_shop.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await showUpsertShopDialog(
                context,
                database,
                existingShop: _shop,
              );
              if (updated != null && mounted) {
                setState(() {
                  _shop = updated;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final count =
                  await (database.select(database.prices)
                        ..where((t) => t.shopId.equals(_shop.id)))
                      .get()
                      .then((l) => l.length);

              if (!context.mounted) return;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteShop),
                  content: Text(
                    'Deleting this shop will delete $count price records.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () async {
                        await database.transaction(() async {
                          await (database.delete(
                            database.shopEvents,
                          )..where((t) => t.shopId.equals(_shop.id))).go();
                          await (database.delete(
                            database.prices,
                          )..where((t) => t.shopId.equals(_shop.id))).go();
                          await (database.delete(
                            database.shops,
                          )..where((t) => t.id.equals(_shop.id))).go();
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
            // Shop Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.store,
                            size: 28,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _shop.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_shop.memo != null && _shop.memo!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.shopMemo,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_shop.memo!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Events Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.shopEvents,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await showUpsertShopEventDialog(
                      context,
                      database,
                      shopId: _shop.id,
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addEvent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<ShopEvent>>(
              stream:
                  (database.select(database.shopEvents)
                        ..where((t) => t.shopId.equals(_shop.id))
                        ..orderBy([
                          (t) => drift.OrderingTerm(
                            expression: t.createdAt,
                            mode: drift.OrderingMode.desc,
                          ),
                        ]))
                      .watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noEvents,
                              style: TextStyle(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final events = snapshot.data!;
                return Column(
                  children: events.map((event) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: event.eventType == 'recurring'
                              ? colorScheme.tertiaryContainer
                              : colorScheme.secondaryContainer,
                          child: Icon(
                            event.eventType == 'recurring'
                                ? Icons.repeat
                                : Icons.event,
                            color: event.eventType == 'recurring'
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_buildEventSubtitle(event, l10n)),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.editEvent),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.deleteEvent,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await showUpsertShopEventDialog(
                                context,
                                database,
                                shopId: _shop.id,
                                existingEvent: event,
                              );
                            } else if (value == 'delete') {
                              await (database.delete(
                                database.shopEvents,
                              )..where((t) => t.id.equals(event.id))).go();
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildEventSubtitle(ShopEvent event, AppLocalizations l10n) {
    if (event.eventType == 'recurring') {
      final parts = <String>[];
      if (event.dayOfWeek != null) {
        final dayNames = [
          l10n.monday,
          l10n.tuesday,
          l10n.wednesday,
          l10n.thursday,
          l10n.friday,
          l10n.saturday,
          l10n.sunday,
        ];
        if (event.dayOfWeek! >= 1 && event.dayOfWeek! <= 7) {
          parts.add('${l10n.recurring}: ${dayNames[event.dayOfWeek! - 1]}');
        }
      }
      if (event.dayOfMonth != null) {
        parts.add('${l10n.recurring}: ${event.dayOfMonth}日');
      }
      if (event.description != null && event.description!.isNotEmpty) {
        parts.add(event.description!);
      }
      return parts.join(' / ');
    } else {
      // One-time
      final parts = <String>[];
      if (event.date != null) {
        parts.add(DateFormat.yMMMd().format(event.date!));
      }
      if (event.description != null && event.description!.isNotEmpty) {
        parts.add(event.description!);
      }
      return parts.isNotEmpty ? parts.join(' / ') : l10n.oneTime;
    }
  }
}
