import 'package:beehive/debug/module/leasson1.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPagesUploader extends StatefulWidget {
  const AddPagesUploader({super.key});
  @override
  _AddPagesUploaderState createState() => _AddPagesUploaderState();
}

class _AddPagesUploaderState extends State<AddPagesUploader> {
  String _message = 'Press button to add 3 PAGES (with content as an Array) to modules/module1/lessons/1';
  bool _isLoading = false;

  Future<void> _uploadPages() async {
    setState(() { _isLoading = true; _message = 'Adding pages...'; });

    final firestore = FirebaseFirestore.instance;
    // This path is hard-coded to your existing lesson
    final lessonRef = firestore
        .collection('modules')
        .doc('module1')
        .collection('lessons')
        .doc('1');

    WriteBatch batch = firestore.batch();
    int pageCount = 0;

    try {
      // 1. Loop through all PAGES in your file
      for (final pageData in lesson1Pages) {
        
        final pageRef = lessonRef.collection('pages').doc(); // New Auto-ID
        
        // This is the new simple logic:
        batch.set(pageRef, {
          'title': pageData['pageTitle'],
          'order': pageData['pageOrder'],
          'createdAt': FieldValue.serverTimestamp(),
          // 🌟 This saves the entire 'blocks' list as an Array field 🌟
          'content_blocks': pageData['blocks'], 
        });
        
        pageCount++;
      }

      // 2. COMMIT
      await batch.commit();
      setState(() {
        _message = '✅ SUCCESS!\nAdded: $pageCount Pages to modules/module1/lessons/1';
        _isLoading = false;
      });

    } catch (e) {
      setState(() { _message = '❌ ERROR: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Page Uploader')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _uploadPages,
                  icon: Icon(Icons.upload),
                  label: Text('Add 3 Pages'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}