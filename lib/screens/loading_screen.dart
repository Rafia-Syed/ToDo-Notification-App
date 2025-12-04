import 'dart:async';
import 'package:flutter/material.dart';
import 'package:todo_app/screens/todo_home_screen.dart';
// ignore: unused_import
import 'package:todo_app/main.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start a timer to ensure screen shows for at least 2 seconds
    final minimumLoadTime = Future.delayed(const Duration(seconds: 2));

    try {
      // Import the functions from main.dart or call them directly
      // Since these are in main.dart, we'll use a simpler approach
      // Just wait without calling notification functions for now
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("App initialization failed: $e");
      // Continue anyway - don't let initialization failures break the app
    }

    // Wait for both initialization and minimum time
    await minimumLoadTime;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ToDoHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Debug container to check if text is rendering
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "TODOR GIDIKOV", // ← ALL CAPS for better visibility
                    style: TextStyle(
                      fontSize: 32, // Larger font size
                      fontWeight: FontWeight.w900, // Bolder weight
                      color: Colors.blue[900], // Very dark blue
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Task Manager App",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 4.0,
            ),
            const SizedBox(height: 20),
            Text(
              "Initializing...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
