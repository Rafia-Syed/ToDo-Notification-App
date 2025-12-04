import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/provider/to_do_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:todo_app/screens/loading_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'todo_channel',
  'ToDo Notifications',
  description: 'Reminder notifications for tasks',
  importance: Importance.max,
);

// Centralized permission management
class AppPermissions {
  static Future<bool> initializeAppPermissions() async {
    try {
      await _initializeNotifications();
      await _requestEssentialPermissions();
      return true;
    } catch (e) {
      debugPrint("Permission initialization failed: $e");
      return false;
    }
  }

  static Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint("Notification initialization failed: $e");
    }
  }

  static Future<void> _requestEssentialPermissions() async {
    try {
      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      
      // Request battery optimization bypass
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted && !batteryStatus.isPermanentlyDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      
      debugPrint("Notification permission: $notificationStatus");
      debugPrint("Battery optimization: $batteryStatus");
    } catch (e) {
      debugPrint("Permission request error: $e");
    }
  }

  // Method to be called from UI when needed (e.g., before scheduling notifications)
  static Future<bool> checkAndRequestNotificationPermissions() async {
    try {
      final notificationStatus = await Permission.notification.status;
      if (notificationStatus.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return notificationStatus.isGranted;
    } catch (e) {
      debugPrint("Notification permission check failed: $e");
      return false;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    tz.initializeTimeZones();
    await AppPermissions.initializeAppPermissions();
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ToDoProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'To Do App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoadingScreen(),
      ),
    );
  }
}