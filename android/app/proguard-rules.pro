# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve annotation information
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature

# For notification compatibility
-keep class android.app.Notification { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }