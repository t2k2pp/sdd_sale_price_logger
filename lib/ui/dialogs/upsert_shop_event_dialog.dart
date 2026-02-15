import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../../data/database.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';

Future<ShopEvent?> showUpsertShopEventDialog(
  BuildContext context,
  AppDatabase database, {
  required int shopId,
  ShopEvent? existingEvent,
}) async {
  final titleController = TextEditingController(text: existingEvent?.title);
  final descController = TextEditingController(
    text: existingEvent?.description,
  );
  String eventType = existingEvent?.eventType ?? 'recurring';
  int? dayOfWeek = existingEvent?.dayOfWeek;
  int? dayOfMonth = existingEvent?.dayOfMonth;
  DateTime? date = existingEvent?.date;
  ShopEvent? result;

  await showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final isEdit = existingEvent != null;
      final dayNames = [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? l10n.editEvent : l10n.addEvent),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: l10n.eventTitle),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.eventDescription,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Event Type Toggle
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'recurring',
                        label: Text(l10n.recurring),
                        icon: const Icon(Icons.repeat, size: 16),
                      ),
                      ButtonSegment(
                        value: 'oneTime',
                        label: Text(l10n.oneTime),
                        icon: const Icon(Icons.event, size: 16),
                      ),
                    ],
                    selected: {eventType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        eventType = newSelection.first;
                        if (eventType == 'recurring') {
                          date = null;
                        } else {
                          dayOfWeek = null;
                          dayOfMonth = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (eventType == 'recurring') ...[
                    // Day of Week
                    DropdownButtonFormField<int?>(
                      decoration: InputDecoration(labelText: l10n.dayOfWeek),
                      initialValue: dayOfWeek,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('-'),
                        ),
                        ...List.generate(7, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(dayNames[i]),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => dayOfWeek = v),
                    ),
                    const SizedBox(height: 12),
                    // Day of Month
                    DropdownButtonFormField<int?>(
                      decoration: InputDecoration(labelText: l10n.dayOfMonth),
                      initialValue: dayOfMonth,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('-'),
                        ),
                        ...List.generate(31, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => dayOfMonth = v),
                    ),
                  ] else ...[
                    // Date Picker for one-time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.date),
                      subtitle: Text(
                        date != null
                            ? '${date!.year}/${date!.month}/${date!.day}'
                            : '-',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => date = picked);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;

                  if (isEdit) {
                    final updated = existingEvent.copyWith(
                      title: titleController.text,
                      description: drift.Value(
                        descController.text.isEmpty
                            ? null
                            : descController.text,
                      ),
                      eventType: eventType,
                      dayOfWeek: drift.Value(dayOfWeek),
                      dayOfMonth: drift.Value(dayOfMonth),
                      date: drift.Value(date),
                    );
                    await database.shopEvents.replaceOne(updated);
                    result = updated;
                  } else {
                    result = await database
                        .into(database.shopEvents)
                        .insertReturning(
                          ShopEventsCompanion(
                            shopId: drift.Value(shopId),
                            title: drift.Value(titleController.text),
                            description: drift.Value(
                              descController.text.isEmpty
                                  ? null
                                  : descController.text,
                            ),
                            eventType: drift.Value(eventType),
                            dayOfWeek: drift.Value(dayOfWeek),
                            dayOfMonth: drift.Value(dayOfMonth),
                            date: drift.Value(date),
                          ),
                        );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isEdit ? l10n.save : l10n.add),
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}
