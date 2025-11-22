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
  final String roomId; // 👈 ADDED: Required for room-specific progress

  const CodeScreen({
    Key? key,
    this.contentID,
    required this.moduleId,
    required this.lessonId,
    required this.roomId, // 👈 ADDED
  }) : super(key: key);

  @override
  _CodeScreenState createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  late final CodeController _codeController;

  String _directions = "Loading instructions...";
  String _guideCode = "";

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
          _isLoading = false;
        });
      }
    }
  }

  // Robust executor (tries multiple hosts)
  Future<void> _executePythonCode() async {
    setState(() {
      _isRunningCode = true;
    });

    final List<String> tryHosts = [
      'http://127.0.0.1:5000',
      'http://10.0.2.2:5000',
      // Add 'http://192.168.x.x:5000' if testing on a device
    ];

    try {
      if (Platform.isAndroid) {
        tryHosts.remove('http://10.0.2.2:5000');
        tryHosts.insert(0, 'http://10.0.2.2:5000');
      } else if (Platform.isIOS) {
        tryHosts.remove('http://127.0.0.1:5000');
        tryHosts.insert(0, 'http://127.0.0.1:5000');
      }
    } catch (_) {}

    String outputText = "";
    Object? lastEx;

    for (final base in tryHosts) {
      final url = Uri.parse('$base/execute');
      try {
        final response = await http
            .post(url, body: {'code': _codeController.text}).timeout(
                const Duration(seconds: 10));
        final data = jsonDecode(response.body);
        final String output = (data['output'] ?? '').toString();
        final String error = (data['error'] ?? '').toString();
        outputText = error.isNotEmpty ? "$output\nError: $error" : output;
        lastEx = null;
        break;
      } on TimeoutException catch (te) {
        lastEx = te;
        continue;
      } catch (e) {
        lastEx = e;
        continue;
      }
    }

    if (lastEx != null && outputText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Error: Could not reach Python server. Check logs or server status.")),
        );
      }
    } else {
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
      }
    }

    if (mounted) {
      setState(() {
        _isRunningCode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCodingMode ? "Code Editor" : "Instructions"),
        leading: _isCodingMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _isCodingMode = false))
            : null,
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

  Widget _buildInstructionsView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 WRAP CONTENT IN EXPANDED + SCROLLVIEW
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Directions:",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(_directions, style: const TextStyle(fontSize: 16)),
                  const Divider(height: 40),
                  const Text("Starter Code:",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.grey[200],
                    width: double.infinity,
                    child: Text(_guideCode,
                        style: const TextStyle(fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 20), // Extra space at bottom of scroll
                ],
              ),
            ),
          ),
          
          // 🌟 BUTTON STAYS FIXED AT THE BOTTOM
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push<String?>(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            IdeScreen(initialCode: _guideCode))).then(
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
              child: const Text("START CODING"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    return CodeEditor(controller: _codeController);
  }
}