import 'package:beehive/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // --- TEMPORARILY DISABLED FOR TESTING ---
  /* try {
    print("Starting embedded Python Flask server...");
    await SeriousPython.run(
      "assets/python/server.zip",
      appFileName: "main.py",
    );
    print("✅ Python server started successfully!");
  } catch (e) {
    print("❌ Failed to start Python server: $e");
  }
  */
  // --- END OF DISABLED BLOCK ---

  // --- Now launch the Flutter UI ---
  runApp(const MyApp()); // Assuming MyApp is in your app.dart
}