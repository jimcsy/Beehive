import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Import your editor widget
import 'package:beehive/python_ide/code_editor.dart';
// Import main to get the theme (if you still have it set up)
import 'package:beehive/main.dart'; 
// Import the full IDE screen (Swarm)
import 'package:beehive/python_ide/ide_test_screen.dart';

class CodeScreen extends StatefulWidget {
  final String? contentID;

  const CodeScreen({Key? key, this.contentID}) : super(key: key);

  @override
  _CodeScreenState createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  late final CodeController _codeController;
  
  // Data variables
  String _directions = "Loading instructions...";
  String _guideCode = "";
  
  // State variables
  bool _isLoading = true; // Loading data from Supabase
  bool _isCodingMode = false; // false = Instructions View, true = Editor View
  bool _isRunningCode = false; // Loading execution (spinner on button)

  @override
  void initState() {
    super.initState();
    
    // Initialize controller
    _codeController = CodeController(
      text: "",
      language: python,
      // theme: ideTheme.theme, // Uncomment if your main.dart theme is working
    );

    if (widget.contentID != null) {
      _loadPracticeProblem();
    } else {
      // Playground mode
      _codeController.text = "print('Hello World')";
      _isLoading = false;
      _isCodingMode = true; 
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeProblem() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('IDEPractice')
          .select()
          .eq('lessonContentId', widget.contentID!)
          .single();

      if (mounted) {
        setState(() {
          // 1. Prepare the data
          _directions = response['directions'] ?? "No directions.";
          String rawCode = response['guideCode'] ?? "";
          _guideCode = rawCode.replaceAll(r'\n', '\n'); // Fix newlines

          // 2. Pre-fill the editor for later
          _codeController.text = _guideCode;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _directions = "Error loading problem.";
        _isLoading = false;
      });
    }
  }

  Future<void> _executePythonCode() async {
    setState(() { _isRunningCode = true; });
    
    // Simple http execution
    try {
      final url = Uri.parse('http://127.0.0.1:5000/execute');
      final response = await http.post(
        url, 
        body: {'code': _codeController.text}
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      
      // Show result in a simple Dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Output"),
            content: Text(data['output'] ?? data['error']),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
       }
    }
    
    setState(() { _isRunningCode = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCodingMode ? "Code Editor" : "Instructions"),
        // Add a back button if we are in coding mode to go back to instructions
        leading: _isCodingMode 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _isCodingMode = false),
            )
          : null, // Default back button
      ),
      
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _isCodingMode 
              ? _buildEditorView() 
              : _buildInstructionsView(),
              
      floatingActionButton: _isCodingMode
        ? FloatingActionButton(
            onPressed: _isRunningCode ? null : _executePythonCode,
            child: _isRunningCode 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.play_arrow),
          )
        : null,
    );
  }

  // --- VIEW 1: The Instructions ---
  Widget _buildInstructionsView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Directions
          const Text("Directions:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_directions, style: const TextStyle(fontSize: 16)),
          
          const Divider(height: 40),
          
          // 2. Preview of the code
          const Text("Starter Code:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[200],
            width: double.infinity,
            child: Text(
              _guideCode, 
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          
          const Spacer(),
          
          // 3. The "Do It" Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Switch to editor mode by opening the Swarm IDE and pass
                // the starter/guide code. Await the result (submitted code).
                Navigator.push<String?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IdeScreen(initialCode: _guideCode),
                  ),
                ).then((submittedCode) async {
                  if (submittedCode != null) {
                    // If we have a contentID, save the submission to Supabase
                    if (widget.contentID != null) {
                      try {
                        final supabase = Supabase.instance.client;
                        await supabase.from('IDESubmissions').insert({
                          'lessonContentId': widget.contentID,
                          'code': submittedCode,
                          'submitted_at': DateTime.now().toIso8601String(),
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Submission saved.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Submit failed: $e')),
                          );
                        }
                      }
                    } else {
                      // Playground mode: just show a confirmation
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code returned from IDE.')),
                        );
                      }
                    }
                  }
                });
              },
              child: const Text("START CODING"),
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 2: The Editor ---
  Widget _buildEditorView() {
    return CodeEditor(
      controller: _codeController,
    );
  }
}