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

  Future<void> _executePythonCode() async {
    setState(() {
      _isLoading = true;
      _consoleOutput = "Running code...\n";
    });

    final scaffoldContext = context;
    showOutputModal(scaffoldContext, _consoleOutput, _isLoading);

    // Hosts to try. Add your machine LAN IP here if testing on a physical device:
    // e.g. 'http://192.168.1.100:5000'
    final List<String> tryHosts = [
      'http://127.0.0.1:5000', // iOS simulator / desktop
      'http://10.0.2.2:5000', // Android emulator
      // 'http://192.168.1.100:5000', // <-- add your dev machine LAN IP if testing on device
    ];

    // Prefer host depending on platform
    try {
      if (Platform.isAndroid) {
        // Android emulator needs 10.0.2.2
        tryHosts.remove('http://10.0.2.2:5000');
        tryHosts.insert(0, 'http://10.0.2.2:5000');
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost
        tryHosts.remove('http://127.0.0.1:5000');
        tryHosts.insert(0, 'http://127.0.0.1:5000');
      }
    } catch (_) {
      // Platform may be unavailable on web; ignore
    }

    String newOutput = "";
    Object? lastException;

    debugPrint("[DEBUG] Code to execute:\n${_codeController.text}");

    for (final base in tryHosts) {
      final url = Uri.parse('$base/execute');
      debugPrint("[DEBUG] Trying python server at: $url");

      try {
        final response = await http.post(url, body: {'code': _codeController.text}).timeout(const Duration(seconds: 15));
        debugPrint("[DEBUG] Response status: ${response.statusCode}");
        debugPrint("[DEBUG] Raw response body: ${response.body}");
        final data = jsonDecode(response.body);

        final String output = (data['output'] ?? '').toString();
        final String error = (data['error'] ?? '').toString();

        if (error.isNotEmpty) {
          newOutput = "$output\nError: $error";
        } else {
          newOutput = output;
        }

        lastException = null;
        break; // success -> stop trying hosts
      } on TimeoutException catch (te) {
        debugPrint("[DEBUG] Timeout to $base: $te");
        lastException = te;
        continue; // try next host
      } catch (e) {
        debugPrint("[DEBUG] Error connecting to $base : $e");
        lastException = e;
        continue; // try next host
      }
    }

    if (lastException != null && newOutput.isEmpty) {
      newOutput = "Error connecting to Python server.\n\nPossible fixes:\n"
          "- Make sure the Python server is running on port 5000.\n"
          "- If you're using Android emulator, the app should use 10.0.2.2:5000.\n"
          "- If you're testing on a real device, add your computer's LAN IP to the host list and open firewall.\n\nLast error: $lastException";
    }

    if (scaffoldContext.mounted) {
      Navigator.pop(scaffoldContext); // close "running" modal
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
