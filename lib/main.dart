import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:serious_python/serious_python.dart';


// 🌟 --- 1. IMPORT YOUR NEW FIREBASE FILE --- 🌟
import 'firebase_options.dart'; 

// 🌟 --- 2. ADD SUPABASE IMPORT --- 🌟
import 'package:supabase_flutter/supabase_flutter.dart';

// Your app's existing files
import 'app.dart';
import 'python_ide/ide_test_screen.dart';

// Your theme file
import 'python_ide/ide_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- 3. INITIALIZE FIREBASE (Correctly) ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // --- 4. 🌟 INITIALIZE SUPABASE --- 🌟
  // Use `Supabase.initialize` (correct API) instead of `initializeApp`.
  await Supabase.initialize(
    url: 'https://mdfvotpfdlvqarftfixj.supabase.co', // 👈 Paste your Project URL here
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZnZvdHBmZGx2cWFyZnRmaXhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMzg3MzMsImV4cCI6MjA3ODYxNDczM30.JH0y-CevUEghtsEjn_l2S_vbTmOAreVMwg2fMXjwgkA', // 👈 Paste your anon key here
  );
  // ------------------------------------

  // --- 5. INITIALIZE YOUR CODE THEME ---
  await initIdeTheme(); // This is your function

  // --- 6. START THE PYTHON SERVER ---
  /*SeriousPython.run("assets/python_assets/final_bundle.zip", appFileName: "main.py").then((_) {
    print("Python server process has started in the background.");
  }).catchError((e) {
    print("Error starting Python server in background: $e");
  });*/

  // --- 7. RUN YOUR APP ---
  runApp(const MyApp());
}