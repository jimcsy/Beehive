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
        ),
        home: Wrapper(), // This will listen for auth state
      ),
    );
  }
}
