import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:beehive/python_ide/code_editor.dart';
import 'package:beehive/main.dart';
import 'package:beehive/python_ide/ide_test_screen.dart';
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
  String _lessonTitle = "Introduction to Python"; // You can make this dynamic later
  String _subTitle = "Basic Operators"; // You can make this dynamic later
  String _directions = "Loading instructions...";
  String _guideCode = "";
  String _expectedOutput = "Loading expected output..."; // New variable for the black box

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
          _directions = response['directions'] ?? "No directions.";
          
          // Handle expected output (Mocking it if DB column doesn't exist yet)
          _expectedOutput = response['expectedOutput'] ?? 
              "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet";

          String rawCode = response['guideCode'] ?? "";
          _guideCode = rawCode.replaceAll(r'\n', '\n');
          _codeController.text = _guideCode;
          _isLoading = false;
        });
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

  // === REPLACED: integrated your old simple executor ===
  Future<void> _executePythonCode() async {
    setState(() {
      _isRunningCode = true;
    });

    // Simple http execution (uses localhost)
    try {
      final url = Uri.parse('http://127.0.0.1:5000/execute');
      final response = await http.post(
        url,
        body: {'code': _codeController.text},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      // Show result in a simple Dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Output"),
            content: Text(data['output'] ?? data['error']),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    setState(() {
      _isRunningCode = false;
    });
  }
  // === end integrated executor ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match clean white background
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
          // 🌟 SCROLLABLE CONTENT AREA
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
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
                  
                  // Subtitle
                  Center(
                    child: Text(
                      _subTitle,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w500,
                        color: Colors.black87
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Directions Header
                  const Text(
                    "Directions:",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Directions Body
                  Text(
                    _directions, 
                    style: TextStyle(
                      fontSize: 14, 
                      height: 1.5, 
                      color: Colors.grey[800]
                    )
                  ),
                  
                  const SizedBox(height: 40),

                  // Expected Output Header
                  const Text(
                    "Expected Output:",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🌟 BLACK BOX (Expected Output, NOT Code)
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
                        fontFamily: 'monospace', // Terminal look
                        fontSize: 14,
                        height: 1.4
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ),
           
          // 🌟 GOLD "CONTINUE" BUTTON
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9F7426), // Gold/Brown color from image
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push<String?>(context, MaterialPageRoute(builder: (context) => IdeScreen(initialCode: _guideCode))).then(
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission saved.')));
                        }
                        try {
                          // NOTE: ProgressService signature expects moduleId & lessonId
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code returned from IDE.')));
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
          const SizedBox(height: 20), // Bottom safe area padding
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    return CodeEditor(controller: _codeController);
  }
}
