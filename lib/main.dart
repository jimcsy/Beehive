import 'package:beehive/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:serious_python/serious_python.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // --- Run the embedded Python server before app start ---
  try {
    print("Starting embedded Python Flask server...");
    await SeriousPython.run(
      "assets/python/server.zip",
      appFileName: "main.py",
    );
    print("✅ Python server started successfully!");
  } catch (e) {
    print("❌ Failed to start Python server: $e");
  }

  // --- Now launch the Flutter UI ---
  runApp(const MyApp());
}
