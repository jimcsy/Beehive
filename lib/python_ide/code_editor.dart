// lib/python_ide/code_editor.dart
import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeEditor extends StatefulWidget {
  final CodeController controller;
  const CodeEditor({Key? key, required this.controller}) : super(key: key);

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: CodeField(
        controller: widget.controller,
        textStyle: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.5),
        lineNumbers: true,
        expands: true,
        maxLines: null,
        decoration: BoxDecoration(
          color: monokaiSublimeTheme['root']?.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      ),
    );
  }
}