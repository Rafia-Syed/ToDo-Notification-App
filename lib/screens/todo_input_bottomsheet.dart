import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/models/todo_model.dart';
import 'package:todo_app/provider/to_do_provider.dart';
import 'package:todo_app/main.dart'; // Uses AppPermissions class
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/permissions.dart';

class ToDoInputBottomsheet extends StatefulWidget {
  final ToDoModel? task;
  const ToDoInputBottomsheet({super.key, this.task});

  @override
  State<ToDoInputBottomsheet> createState() => _ToDoInputBottomsheetState();
}

class _ToDoInputBottomsheetState extends State<ToDoInputBottomsheet> {
  late TextEditingController title;
  late TextEditingController description;
  late DateTime pickedDate;
  bool _isSaving = false;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.task?.title ?? '');
    description = TextEditingController(text: widget.task?.description ?? '');
    pickedDate = widget.task != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.task!.dateTime)
        : DateTime.now();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  selectDateTime() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2055, 12, 31),
    );

    if (!mounted) return;
    if (selectedDate != null) {
      setState(() {
        pickedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          pickedDate.hour,
          pickedDate.minute,
        );
      });
    }
  }

  selectTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(pickedDate),
    );
    if (!mounted) return;
    if (selectedTime != null) {
      setState(() {
        pickedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      });
    }
  }

  Future<bool> _needExactAlarmPermission() async {
    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt >= 31;
    } catch (e) {
      debugPrint("Error checking Android version: $e");
      return false;
    }
  }

  Future<void> scheduleNotification(ToDoModel task) async {
    try {
      if (task.dateTime <= DateTime.now().millisecondsSinceEpoch) {
        debugPrint("Skipping notification: time is in the past");
        return;
      }

      // Use centralized permission check
      final hasNotificationPermission = await AppPermissions.checkAndRequestNotificationPermissions();
      if (!hasNotificationPermission) {
        debugPrint("Notification permission denied");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enable notifications for reminders"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check Android version and request exact alarm permission for Android 12+
      if (await _needExactAlarmPermission()) {
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        if (alarmStatus.isDenied) {
          final requestedStatus = await Permission.scheduleExactAlarm.request();
          if (!requestedStatus.isGranted && mounted) {
            await showPermissionDialog(context);
            return;
          }
        }
      }

      // Cancel any existing notification for this task
      if (task.id != null) {
        await flutterLocalNotificationsPlugin.cancel(task.id!);
      }

      final scheduledTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.local,
        task.dateTime,
      );

      debugPrint("Scheduling notification for: $scheduledTime");

      int notificationId = task.id ?? DateTime.now().millisecondsSinceEpoch % 1000000;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Reminder: ${task.title}',
        task.description.isNotEmpty ? task.description : 'You have a task to complete!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel',
            'ToDo Notifications',
            channelDescription: 'Reminder notifications for tasks',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: 'todologo_no_bg',
            channelShowBadge: true,
            timeoutAfter: 3600000,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_reminder_${task.id}',
      );

      debugPrint("Notification scheduled successfully with ID: $notificationId");
    } catch (e) {
      debugPrint("Failed to schedule notification: $e");
    }
  }

  Future<void> _saveTask() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    String enteredTitle = title.text.trim();
    String enteredDesc = description.text.trim();

    if (enteredTitle.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Title cannot be empty"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    try {
      // Create task model with proper done field
      ToDoModel model = ToDoModel(
        id: widget.task?.id,
        dateTime: pickedDate.millisecondsSinceEpoch,
        description: enteredDesc,
        title: enteredTitle,
        done: widget.task?.done ?? false, // Preserve existing done status when editing
      );

      // Save task to database
      if (widget.task == null) {
        await context.read<ToDoProvider>().addToDo(model);
      } else {
        await context.read<ToDoProvider>().updateToDo(model);
      }

      // Try to schedule notification
      try {
        await scheduleNotification(model);
      } catch (e) {
        debugPrint("Notification scheduling failed but task was saved: $e");
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task saved successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Close bottom sheet
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error saving task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save task. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null ? "Add New Task" : "Edit Task",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            Text(
              "Task Title *",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: title,
              decoration: InputDecoration(
                hintText: "Enter task title...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // Description Field
            Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: description,
              decoration: InputDecoration(
                hintText: "Enter task description (optional)...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              maxLines: 4,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Date & Time Selection
            Text(
              "Schedule",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectDateTime,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text("Select Date"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text("Select Time"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Selected Date & Time Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.schedule, size: 24, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    "Scheduled for",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE, MMM dd, yyyy').format(pickedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(pickedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : const Text(
                          "SAVE TASK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Reminder Note
            if (widget.task == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You'll receive a reminder notification at the scheduled time",
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
