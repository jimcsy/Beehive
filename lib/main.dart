import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serious_python/serious_python.dart';

// 🌟 --- 1. ADD THIS IMPORT --- 🌟
// Your app's existing files
import 'app.dart';
import 'python_ide/ide_test_screen.dart';

// Move theme initialization into a small module to avoid circular imports
import 'python_ide/ide_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize the syntax highlighter/theme before the app starts
  await initIdeTheme();

  // --- 4. START THE PYTHON SERVER ---
  SeriousPython.run("assets/python_assets/final_bundle.zip", appFileName: "main.py").then((_) {
    print("Python server process has started in the background.");
  }).catchError((e) {
    print("Error starting Python server in background: $e");
  });

  // --- 5. RUN YOUR APP ---
  runApp(const MyApp());
}