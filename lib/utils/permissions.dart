import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> isExactAlarmPermissionGranted() async {
  return await Permission.scheduleExactAlarm.isGranted;
}

Future<void> openAlarmPermissionSettings() async {
  try {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    await intent.launch();
  } catch (e) {
    debugPrint("Could not launch exact alarm settings: $e");
    await openAppSettings();
  }
}

Future<void> showPermissionDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Alarm Permission Required'),
      content: const Text(
        'To set accurate reminders for your tasks, please grant "Allow setting exact alarms" permission.\n\n'
        'This ensures you receive notifications at the exact time you specify.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not Now'),
        ),
        TextButton(
          onPressed: () {
            openAlarmPermissionSettings();
            Navigator.pop(context);
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}