import 'package:beehive/start/landing_page.dart';
import 'package:beehive/start/practice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'start/wrapper.dart';
import 'start/google_sign_in.dart';
import 'start/loader.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
          primarySwatch: Colors.amber,

          bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: const Color(0xFFA27221), // Your selected icon color
          unselectedItemColor: Colors.grey,           // Unselected icons
          backgroundColor: Colors.white,              // Background color
          enableFeedback: true,                       // Enable tap feedback
          type: BottomNavigationBarType.fixed,        // Fixed type (optional)
        ),
        splashColor: Color(0xFFF4E3C2),                   // Ripple color when tapped
        highlightColor: Color(0xFFF4E3C2).withOpacity(0.2), // Highlight when tapping
        ),
        home: Wrapper(), // This will listen for auth state
      ),
    );
  }
}
