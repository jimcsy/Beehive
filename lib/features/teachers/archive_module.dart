import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchiveLessonPage extends StatefulWidget {
  final String moduleId;
  const ArchiveLessonPage({super.key, required this.moduleId});

  @override
  State<ArchiveLessonPage> createState() => _ArchiveLessonPageState();
}

class _ArchiveLessonPageState extends State<ArchiveLessonPage> {
  @override
  Widget build(BuildContext context) {
    final lessonsRef = FirebaseFirestore.instance
        .collection('modules')
        .doc(widget.moduleId)
        .collection('lessons')
        .where('isArchived', isEqualTo: false); // only active lessons

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive Lessons'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: lessonsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No lessons available.'));
          }

          final lessons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final lessonId = lesson.id;
              final lessonTitle = lesson['title'] ?? 'Untitled';
              final lessonDesc = lesson['description'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    lessonTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lessonDesc,
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
                        await FirebaseFirestore.instance
                            .collection('modules')
                            .doc(widget.moduleId)
                            .collection('lessons')
                            .doc(lessonId)
                            .update({'isArchived': true});

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('"$lessonTitle" archived successfully'),
                        ));
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
