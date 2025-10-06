import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'start/wrapper.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

// MyApp is the root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Wrapper(),
    );
  }
}

// HomePage is the main screen of the app
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variable to store the counter value
  int _counter = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(
          Icons.menu,
          color: Colors.white,
        ), // Set the leading icon
        
        // Set the background color of the app bar
        backgroundColor: Colors.green,
        
        // Set the title of the app bar
        title: const Text(
          "GeeksforGeeks",
          style: TextStyle(
            
            // Set the text color
            color: Colors.white, 
          ),
        ),
      ),
      
      // The main body of the scaffold
      body: Center(
        
        // Display a centered text widget
        child: Text(
          "$_counter",
          
          // Apply text styling
          style: const TextStyle(
            
            // Set font size
            fontSize: 24, 
            
            // Set font weight
            fontWeight: FontWeight.bold, 
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          // Increment the counter value by 1 using setState
          setState(() {
            _counter++;
          });
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}