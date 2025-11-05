import 'package:beehive/core/models/lesson_module.dart';
import 'package:beehive/core/services/firestore_services.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NO LONGER NEEDED

// --- 2. ADD IMPORTS ---
import 'package:provider/provider.dart';

class ArchiveLessonPage extends StatefulWidget {
  final String moduleId;
  const ArchiveLessonPage({super.key, required this.moduleId});

  @override
  State<ArchiveLessonPage> createState() => _ArchiveLessonPageState();
}

class _ArchiveLessonPageState extends State<ArchiveLessonPage> {
  @override
  Widget build(BuildContext context) {
    // 3. --- GET SERVICE FROM PROVIDER ---
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive Lessons'),
      ),
      // 4. --- UPDATED STREAMBUILDER ---
      body: StreamBuilder<List<LessonModel>>(
        // Use the new service function
        stream: firestoreService.modules.getActiveLessonsStream(widget.moduleId), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No lessons available.'));
          }

          // 5. --- USE THE CLEAN LIST<LESSONMODEL> ---
          final lessons = snapshot.data!;

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              // 'lesson' is now a clean LessonModel object
              final lesson = lessons[index]; 
              final lessonId = lesson.id;
              final lessonTitle = lesson.title;
              final lessonDesc = lesson.description;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    lessonTitle, // <-- Clean property
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lessonDesc, // <-- Clean property
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.archive, color: Colors.orange),
                    tooltip: 'Archive Lesson',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Archive Lesson'),
                          content: Text(
                              'Are you sure you want to archive "$lessonTitle"?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Archive',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm ?? false) {
                        // 6. --- USE THE SERVICE TO UPDATE ---
                        try {
                          await firestoreService.modules.archiveLesson(
                              widget.moduleId, lessonId);

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('"$lessonTitle" archived successfully'),
                          ));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Failed to archive: $e'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}