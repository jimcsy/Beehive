import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serious_python/serious_python.dart';

// 🌟 --- NEW FCM IMPORT --- 🌟
import 'package:firebase_messaging/firebase_messaging.dart';

// 🌟 --- 1. IMPORT YOUR FIREBASE OPTIONS FILE --- 🌟
import 'firebase_options.dart'; 

// Your service file import (required to save the token)
// import 'package:beehive/core/services/firestore_services.dart'; 
// We will define a minimal helper function here instead of importing the full service.

// 🌟 --- 2. ADD SUPABASE IMPORT --- 🌟
import 'package:supabase_flutter/supabase_flutter.dart';

// Your app's existing files
import 'app.dart';
import 'python_ide/ide_test_screen.dart';

// Your theme file
import 'python_ide/ide_theme.dart';

// --- HELPER FUNCTION TO RUN AFTER AUTH IS READY ---
// This is called AFTER the user is logged in and their UID is available.
// For now, we only define the initialization steps.
void setupFCM() async {
  print("Initializing Firebase Cloud Messaging...");
  
  // 1. Request Notification Permissions (Shows the pop-up dialog)
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission.');
    
    // 2. Get the unique FCM token for this device
    final fcmToken = await FirebaseMessaging.instance.getToken();
    
    // You would typically call a service here to save the token:
    // firestoreService.users.updateFCMToken(currentUserId, fcmToken);
    print('FCM Token generated: $fcmToken');
    
  } else {
    print('User declined or has not yet granted permission: ${settings.authorizationStatus}');
  }

  // 3. Optional: Configure handler for background messages (needed for true background notifications)
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- 3. INITIALIZE FIREBASE (Correctly) ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🚨 NEW: Call the FCM setup function.
  // We call it here to ensure the permission prompt happens early.
  setupFCM(); 

  // --- 4. 🌟 INITIALIZE SUPABASE --- 🌟
  await Supabase.initialize(
    url: 'https://mdfvotpfdlvqarftfixj.supabase.co', // 👈 Paste your Project URL here
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZnZvdHBmZGx2cWFyZnRmaXhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMzg3MzMsImV4cCI6MjA3ODYxNDczM30.JH0y-CevUEghtsEjn_l2S_vbTmOAreVMwg2fMXwggkA', // 👈 Paste your anon key here
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