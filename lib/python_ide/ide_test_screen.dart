import 'package:beehive/python_ide/code_editor.dart';
import 'package:beehive/python_ide/output_modal.dart';
import 'package:beehive/utils/hexagonal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'dart:async'; 

// --- 1. IMPORTS ---
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
// ❗️ You will need these imports if you add the theme back
// import '../main.dart'; 
// import 'package:syntax_highlight/syntax_highlight.dart';


class IdeScreen extends StatefulWidget {
  final String? initialCode;

  const IdeScreen({Key? key, this.initialCode}) : super(key: key);

  @override
  _IdeScreenState createState() => _IdeScreenState();
}

class _IdeScreenState extends State<IdeScreen> {
  late final CodeController _codeController;
  String _consoleOutput = "Welcome to Beehive!\nYour local Python server is running.\n";
  bool _isLoading = false;

  // --- 2. CONTROLLER INITIALIZATION ---
  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: widget.initialCode ?? "# Welcome to Beehive!\nprint('Hello, Python!')",
      language: python,
      // You can add your theme here if you get it working
      // theme: ideTheme.theme,
      // padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
  // -----------------------------------------------

  // ... (Your _executePythonCode is 100% correct) ...
  Future<void> _executePythonCode() async {
    setState(() { _isLoading = true; _consoleOutput = "Running code...\n"; });
    final scaffoldContext = context;
    showOutputModal(scaffoldContext, _consoleOutput, _isLoading);
    final url = Uri.parse('http://127.0.0.1:5000/execute');
    String newOutput = "";
    debugPrint("[DEBUG] Sending POST request to: $url");
    debugPrint("[DEBUG] Code to execute:\n${_codeController.text}");
    try {
      final response = await http.post(
        url,
        body: {'code': _codeController.text},
      ).timeout(const Duration(seconds: 15));
      debugPrint("[DEBUG] Response status: ${response.statusCode}");
      debugPrint("[DEBUG] Raw response body: ${response.body}");
      final data = jsonDecode(response.body);
      if (data['error'].isNotEmpty) {
        newOutput = "${data['output']}\nError: ${data['error']}";
      } else {
        newOutput = data['output'];
      }
    } on TimeoutException {
      debugPrint("[DEBUG] Timeout error: Server took too long to respond.");
      newOutput = "Error: Code execution timed out (15 seconds).";
    } catch (e) {
      debugPrint("[DEBUG] Exception caught: $e");
      newOutput = "Error connecting to Python server:\n$e";
    }
    if (scaffoldContext.mounted) {
      Navigator.pop(scaffoldContext);
    }
    setState(() {
      _consoleOutput = newOutput;
      _isLoading = false;
    });
    if (scaffoldContext.mounted) {
      showOutputModal(scaffoldContext, _consoleOutput, _isLoading);
    }
    debugPrint("[DEBUG] Final console output:\n$_consoleOutput");
  }


  @override
  Widget build(BuildContext context) {
    // 🌟 --- 1. WRAP YOUR SCAFFOLD IN PopScope --- 🌟
    return PopScope(
      // 2. This stops the app from going back automatically
      canPop: false, 
      
      // 3. This function runs INSTEAD of the back button
      onPopInvoked: (bool didPop) async {
        // 'didPop' will be false because we set canPop to false
        if (didPop) {
          return;
        }

        // 4. This is your logic: hide the keyboard
        FocusManager.instance.primaryFocus?.unfocus();

        // 5. Wait a moment for the keyboard to animate away
        await Future.delayed(const Duration(milliseconds: 100));

        // 6. NOW manually go back
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2b2b2b),
        appBar: AppBar(
          title: const Text("Swarm", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFE8A319),
          elevation: 0,
          // The back button here will now be handled by the PopScope
          iconTheme: const IconThemeData(
            color: Colors.white, // This makes the back button white
          ),
          actions: [
            // Submit button: returns the current code to the caller
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                // Return the current code as the result
                Navigator.of(context).pop(_codeController.text);
              },
            ),
          ],
        ),
        
        body: CodeEditor(
          controller: _codeController,
        ),

        floatingActionButton: HexFloatingButton(
          onPressed: _isLoading ? () {} : _executePythonCode,
          color: _isLoading ? Colors.grey.shade700 : const Color.fromARGB(255, 232, 163, 25),
          size: 70,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.play_arrow, color: Colors.white, size: 50),
        ),
      ),
    );
  }
}