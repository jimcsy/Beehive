import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Keep your project specific imports
import 'package:beehive/python_ide/code_editor.dart';
import 'package:beehive/python_ide/ide_test_screen.dart'; // Ensure this matches your file name for IdeScreen
import 'package:beehive/features/students/modules/progress_service.dart';

class CodeScreen extends StatefulWidget {
  final String? contentID;
  final String moduleId;
  final String lessonId;
  final String roomId;

  const CodeScreen({
    Key? key,
    this.contentID,
    required this.moduleId,
    required this.lessonId,
    required this.roomId,
  }) : super(key: key);

  @override
  _CodeScreenState createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  late final CodeController _codeController;

  // Content Variables
  String _lessonTitle = "Introduction to Python"; 
  String _subTitle = "Basic Operators"; 
  String _directions = "Loading instructions...";
  String _guideCode = "";
  String _expectedOutput = "Loading expected output..."; 

  bool _isLoading = true;
  bool _isCodingMode = false;
  bool _isRunningCode = false;

  @override
  void initState() {
    super.initState();

    _codeController = CodeController(
      text: "",
      language: python,
    );

    if (widget.contentID != null) {
      _loadPracticeProblem();
    } else {
      // Fallback if no content ID provided
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
      // ✅ FIX: Use maybeSingle() to prevent crash if data is missing
      final response = await supabase
          .from('IDEPractice')
          .select()
          .eq('lessonContentId', widget.contentID!)
          .maybeSingle(); 

      if (mounted) {
        if (response == null) {
           setState(() {
            _directions = "Problem not found in database.";
            _expectedOutput = "N/A";
            _isLoading = false;
          });
        } else {
          setState(() {
            _directions = response['directions'] ?? "No directions.";
            _expectedOutput = response['expectedOutput'] ?? "No expected output provided.";
            
            String rawCode = response['guideCode'] ?? "";
            _guideCode = rawCode.replaceAll(r'\n', '\n');
            _codeController.text = _guideCode;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading practice problem: $e");
      if (mounted) {
        setState(() {
          _directions = "Error loading problem.";
          _expectedOutput = "Error loading data.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _executePythonCode() async {
    setState(() {
      _isRunningCode = true;
    });

    // ✅ FIX: Embedded Python always listens on 127.0.0.1 inside the device
    final String url = 'http://127.0.0.1:5000/execute';

    String outputText = "";

    try {
      final response = await http
          .post(Uri.parse(url), body: {'code': _codeController.text})
          .timeout(const Duration(seconds: 10)); // 10s timeout

      final data = jsonDecode(response.body);
      final String output = (data['output'] ?? '').toString();
      final String error = (data['error'] ?? '').toString();
      
      outputText = error.isNotEmpty ? "$output\nError: $error" : output;

    } on TimeoutException {
      outputText = "Error: Connection timed out. \nThe Python server is still starting up. Please try again in 5 seconds.";
    } catch (e) {
      outputText = "Error connecting to Python server:\n$e\n\nEnsure start_server() is running in your Python script.";
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Output"),
          content: Text(outputText),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        ),
      );
      setState(() {
        _isRunningCode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          _isCodingMode ? "Code Editor" : "", 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_isCodingMode) {
              setState(() => _isCodingMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA07020)))
          : _isCodingMode
              ? _buildEditorView()
              : _buildInstructionsView(),
      floatingActionButton: _isCodingMode
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFA07020),
              onPressed: _isRunningCode ? null : _executePythonCode,
              child: _isRunningCode
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.play_arrow),
            )
          : null,
    );
  }

  Widget _buildInstructionsView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      _lessonTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w900,
                        color: Colors.black
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Center(
                    child: Text(
                      _subTitle,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w500,
                        color: Colors.black87
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "Directions:",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    _directions, 
                    style: TextStyle(
                      fontSize: 14, 
                      height: 1.5, 
                      color: Colors.grey[800]
                    )
                  ),
                  
                  const SizedBox(height: 40),

                  const Text(
                    "Expected Output:",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _expectedOutput,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ),
            
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9F7426), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // ✅ FIX: Navigate to IDE Screen passing the CURRENT user code
                Navigator.push<String?>(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            // We pass _codeController.text so user edits are preserved
                            IdeScreen(initialCode: _codeController.text))).then(
                  (submittedCode) async {
                  if (submittedCode != null) {
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
                              const SnackBar(content: Text('Submission saved.')));
                        }
                        try {
                          await ProgressService().markLessonAsCompleted(
                            roomId: widget.roomId,
                            moduleId: widget.moduleId,
                            lessonId: widget.lessonId,
                          );
                        } catch (e) {
                          debugPrint('Failed to mark code lesson complete: $e');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Submit failed: $e')));
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code returned from IDE.')));
                      }
                    }
                  }
                });
              },
              child: const Text(
                "Continue",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    return CodeEditor(controller: _codeController);
  }
}