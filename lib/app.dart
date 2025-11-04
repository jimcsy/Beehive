import 'package:beehive/core/services/google_auth_services.dart';
import 'package:beehive/core/provider/wrapper.dart';
import 'package:beehive/core/services/firestore_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GoogleSignInProvider(),
        ),
        
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
      ],
      
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
        home: const Wrapper(), // 'const' added here
      ),
    );
  }
}