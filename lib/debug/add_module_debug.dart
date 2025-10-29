import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddModulePage extends StatelessWidget {
  const AddModulePage({super.key});

  // 🔹 Get next module ID dynamically (auto-increment)
  Future<String> _getNextModuleId() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('modules').get();

    int highest = 0;
    for (var doc in snapshot.docs) {
      final id = doc.id;
      if (id.startsWith('module')) {
        final num = int.tryParse(id.replaceFirst('module', '')) ?? 0;
        if (num > highest) highest = num;
      }
    }
    return 'module${highest + 1}';
  }

  // 🔹 Create a module with lessons 1–8 (each with category & title)
  Future<void> createFullModule(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final nextModuleId = await _getNextModuleId();
    final moduleDoc = firestore.collection('modules').doc(nextModuleId);

    final batch = firestore.batch();

    // 1️⃣ Create the module document
    batch.set(moduleDoc, {
      'title': 'Module ${nextModuleId.replaceAll("module", "")}',
      'description': 'This is the description for Module ${nextModuleId.replaceAll("module", "")}.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Create 8 lessons under modules/{moduleX}/lessons/{1–8}
    for (int i = 1; i <= 8; i++) {
      final lessonDoc = moduleDoc.collection('lessons').doc(i.toString());
      batch.set(lessonDoc, {
        'category': 'reading',
        'title': 'Lesson $i',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit all writes in a batch
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Successfully added $nextModuleId with lessons 1–8!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Module Creator')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Click the button to automatically add a new module '
                '(incremented ID) with a "lessons" collection containing 8 lessons (1–8).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async => await createFullModule(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Module with Lessons 1–8'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
