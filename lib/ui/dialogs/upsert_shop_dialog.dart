import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../../data/database.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';

Future<Shop?> showUpsertShopDialog(
  BuildContext context,
  AppDatabase database, {
  Shop? existingShop,
}) async {
  final nameController = TextEditingController(text: existingShop?.name);
  final memoController = TextEditingController(text: existingShop?.memo);
  Shop? result;

  await showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final isEdit = existingShop != null;
      return AlertDialog(
        title: Text(isEdit ? l10n.editShop : l10n.addShop),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoController,
              decoration: InputDecoration(
                labelText: l10n.shopMemo,
                hintText: '特売日や特徴など',
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                if (isEdit) {
                  final updated = existingShop.copyWith(
                    name: nameController.text,
                    memo: drift.Value(
                      memoController.text.isEmpty ? null : memoController.text,
                    ),
                  );
                  await database.shops.replaceOne(updated);
                  result = updated;
                } else {
                  result = await database
                      .into(database.shops)
                      .insertReturning(
                        ShopsCompanion(
                          name: drift.Value(nameController.text),
                          memo: drift.Value(
                            memoController.text.isEmpty
                                ? null
                                : memoController.text,
                          ),
                        ),
                      );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isEdit ? l10n.save : l10n.add),
          ),
        ],
      );
    },
  );
  return result;
}
