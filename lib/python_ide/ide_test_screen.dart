// lib/ide_test_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode
import 'dart:async';  // For Timeout

class IdeTestScreen extends StatefulWidget {
  const IdeTestScreen({Key? key}) : super(key: key);

  @override
  _IdeTestScreenState createState() => _IdeTestScreenState();
}

class _IdeTestScreenState extends State<IdeTestScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _consoleOutput = "Welcome to Beehive!\nYour local Python server is running.\n";
  bool _isLoading = false;

  

  // This is your runPythonCode function, integrated into the UI
  Future<void> _executePythonCode() async {
  setState(() {
    _isLoading = true;
    _consoleOutput = "Running code...\n";
  });

  final url = Uri.parse('http://10.0.2.2:5000/execute');
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

  setState(() {
    _consoleOutput = newOutput;
    _isLoading = false;
  });

  debugPrint("[DEBUG] Final console output:\n$_consoleOutput");
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beehive Python Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. The Code Editor
            Expanded(
              flex: 2,
              child: TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: "Enter Python code here...\n\nprint('Hello from Python!')",
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            
            const SizedBox(height: 8),

            // 2. The Run Button
            ElevatedButton(
              onPressed: _isLoading ? null : _executePythonCode,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Run Code"),
            ),
            
            const SizedBox(height: 8),

            // 3. The Console Output
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.black87,
                child: SingleChildScrollView(
                  child: Text(
                    _consoleOutput,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}