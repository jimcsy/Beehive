import 'package:beehive/python_ide/code_editor.dart';
import 'package:beehive/python_ide/output_modal.dart';
import 'package:beehive/utils/hexagonal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform; // used to pick host for emulator/device

// --- 1. IMPORTS ---
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
// import '../main.dart'; // optional

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

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: widget.initialCode ?? "# Welcome to Beehive!\nprint('Hello, Python!')",
      language: python,
      // theme: ideTheme.theme,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- INTEGRATED: your old detailed executor (uses 127.0.0.1 and debug logs) ---
  Future<void> _executePythonCode() async {
    setState(() {
      _isLoading = true;
      _consoleOutput = "Running code...\n";
    });

    final scaffoldContext = context;
    showOutputModal(scaffoldContext, _consoleOutput, _isLoading);

    // NOTE: this uses the original hardcoded localhost address (127.0.0.1).
    // If you're testing on Android emulator, change to 10.0.2.2 in this URL.
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

      // The server returns JSON with keys 'output' and 'error'
      if (data['error'] != null && data['error'].toString().isNotEmpty) {
        newOutput = "${data['output'] ?? ''}\nError: ${data['error']}";
      } else {
        newOutput = data['output'] ?? '';
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
  // --- END integrated executor ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2b2b2b),
        appBar: AppBar(
          title: const Text("Swarm", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFE8A319),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop(_codeController.text);
              },
            ),
          ],
        ),
        body: CodeEditor(controller: _codeController),
        floatingActionButton: HexFloatingButton(
          onPressed: _isLoading ? () {} : _executePythonCode,
          color: _isLoading ? Colors.grey.shade700 : const Color.fromARGB(255, 232, 163, 25),
          size: 70,
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Icon(Icons.play_arrow, color: Colors.white, size: 50),
        ),
      ),
    );
  }
}
