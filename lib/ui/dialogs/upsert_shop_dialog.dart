import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../../data/database.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';

Future<Shop?> showUpsertShopDialog(
  BuildContext context,
  AppDatabase database, {
  Shop? existingShop,
}) async {
  final controller = TextEditingController(text: existingShop?.name);
  Shop? result;

  await showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final isEdit = existingShop != null;
      return AlertDialog(
        title: Text(isEdit ? 'Edit Shop' : l10n.addShop),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                if (isEdit) {
                  final updated = existingShop.copyWith(name: controller.text);
                  await database.shops.replaceOne(updated);
                  result = updated;
                } else {
                  result = await database
                      .into(database.shops)
                      .insertReturning(
                        ShopsCompanion(name: drift.Value(controller.text)),
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
