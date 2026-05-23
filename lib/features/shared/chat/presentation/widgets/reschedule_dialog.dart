import 'package:flutter/material.dart';

/// Prompts the user for a new date and time. Returns the chosen
/// [DateTime], or null if the user cancelled at any step.
Future<DateTime?> showReschedulePicker(BuildContext context) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: now.hour, minute: 0),
  );
  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}
