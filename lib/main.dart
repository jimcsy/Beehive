import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serious_python/serious_python.dart';
import 'core/wrapper.dart';
import 'core/google_sign_in.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoogleSignInProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Beehive',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          primarySwatch: Colors.amber,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFFA27221),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            enableFeedback: true,
            type: BottomNavigationBarType.fixed,
          ),
          splashColor: const Color(0xFFF4E3C2),
          highlightColor: const Color(0xFFF4E3C2).withOpacity(0.2),
        ),
        home: Wrapper(),
      ),
    );
  }
}
