import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddModulePage extends StatelessWidget {
  const AddModulePage({super.key});

  // 🔹 Get next module ID dynamically (auto-increment)
  Future<String> _getNextModuleId() async {
    // ... [ The code you already have ] ...
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

  // 🔹 Create a module, its lessons, and student progress documents
  Future<void> createFullModule(BuildContext context) async {
    // ... [ The code from the previous step ] ...
    final firestore = FirebaseFirestore.instance;
    final nextModuleId = await _getNextModuleId();
    final moduleDoc = firestore.collection('modules').doc(nextModuleId);
    final moduleNum = nextModuleId.replaceAll('module', '');
    final moduleNumPadded = moduleNum.padLeft(2, '0');
    final batch = firestore.batch();
    batch.set(moduleDoc, {
      'title': 'Module $moduleNum',
      'description': 'This is the description for Module $moduleNum.',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final Map<String, bool> lessonsProgressMap = {};
    for (int i = 1; i <= 7; i++) {
      final lessonNumPadded = i.toString().padLeft(2, '0');
      final lessonId = 'M$moduleNumPadded-L$lessonNumPadded';
      final lessonDoc = moduleDoc.collection('lessons').doc(lessonId);
      batch.set(lessonDoc, {
        'category': 'reading',
        'title': 'Lesson $i ($lessonId)',
        'createdAt': FieldValue.serverTimestamp(),
      });
      lessonsProgressMap[lessonId] = false;
    }
    await batch.commit();
    try {
      final studentQuery = await firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      if (studentQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Module created, but no student users found to update.')),
        );
        return;
      }
      final studentBatch = firestore.batch();
      final progressData = {
        'moduleId': nextModuleId,
        'completed': false,
        'lessons': lessonsProgressMap,
      };
      for (final studentDoc in studentQuery.docs) {
        final progressDocRef = studentDoc.reference
            .collection('progress')
            .doc(nextModuleId);
        studentBatch.set(progressDocRef, progressData);
      }
      await studentBatch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '✅ Successfully added $nextModuleId and updated progress for ${studentQuery.docs.length} students!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating student progress: $e')),
        );
      }
    }
  }

  // --- ⬇️ NEW DELETE FUNCTION ⬇️ ---

  /// This finds all "student" users, finds their "progress" subcollection,
  /// and deletes every document inside it.
  Future<void> _deleteAllStudentProgress(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting delete... This may take a moment.')),
    );

    try {
      // 1. Find all students
      final studentQuery = await firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      if (studentQuery.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No student users found.')),
          );
        }
        return;
      }

      // A batch can only hold 500 operations. We need to handle large deletes.
      WriteBatch batch = firestore.batch();
      int operations = 0;
      int totalDeletedDocs = 0;

      // 2. Loop through each student
      for (final studentDoc in studentQuery.docs) {
        // 3. Get all documents in their "progress" subcollection
        final progressQuery =
            await studentDoc.reference.collection('progress').get();

        if (progressQuery.docs.isEmpty) {
          continue; // This student has no progress docs, skip to next student
        }

        // 4. Loop through each progress document and add it to the batch delete
        for (final progressDoc in progressQuery.docs) {
          batch.delete(progressDoc.reference);
          operations++;
          totalDeletedDocs++;

          // 5. If batch is full, commit it and start a new one
          if (operations >= 499) {
            await batch.commit();
            batch = firestore.batch();
            operations = 0;
          }
        }
      }

      // 6. Commit any remaining operations in the last batch
      if (operations > 0) {
        await batch.commit();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '✅ Success! Deleted $totalDeletedDocs progress documents from ${studentQuery.docs.length} students.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during delete: $e')),
        );
      }
    }
  }

  // --- ⬆️ END OF NEW FUNCTION ⬆️ ---

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
                '(incremented ID) with 7 lessons AND create a progress entry for all students.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async => await createFullModule(context),
                icon: const Icon(Icons.add_task),
                label: const Text('Add Module & Update Students'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              // --- ⬇️ NEW DELETE BUTTON ⬇️ ---
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'DEBUG: This will delete ALL documents inside the "progress" subcollection for ALL students.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async => await _deleteAllStudentProgress(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text('DELETE ALL STUDENT PROGRESS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800], // Danger color
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              // --- ⬆️ END OF NEW BUTTON ⬆️ ---
            ],
          ),
        ),
      ),
    );
  }
}