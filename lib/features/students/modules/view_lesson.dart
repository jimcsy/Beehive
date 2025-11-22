import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:beehive/features/students/modules/view_lesson_layout.dart'; 

// --- 1. DATA & STATE LOGIC ---

class ViewUnitsTab extends StatefulWidget {
  final String roomId;
  final String moduleId;
  final String userId;

  const ViewUnitsTab({
    super.key,
    required this.roomId,
    required this.moduleId,
    required this.userId,
  });

  @override
  State<ViewUnitsTab> createState() => _ViewUnitsTabState();
}

class _ViewUnitsTabState extends State<ViewUnitsTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final moduleRef =
        FirebaseFirestore.instance.collection('modules').doc(widget.moduleId);

    final uniqueProgressId = '${widget.roomId}_${widget.moduleId}';

    final progressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('progress')
        .doc(uniqueProgressId);

    return FutureBuilder<DocumentSnapshot>(
      future: moduleRef.get(),
      builder: (context, moduleSnapshot) {
        if (moduleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (moduleSnapshot.hasError) {
          return Center(child: Text('Error: ${moduleSnapshot.error}'));
        }
        if (!moduleSnapshot.hasData || !moduleSnapshot.data!.exists) {
          return const Center(child: Text('Module not found.'));
        }

        final moduleData =
            moduleSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final moduleTitle = moduleData['title'] ?? 'Untitled Module';
        final lessonsRef = moduleRef.collection('lessons');

        return StreamBuilder<DocumentSnapshot>(
          stream: progressRef.snapshots(),
          builder: (context, progressSnapshot) {
            if (progressSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (progressSnapshot.hasError) {
              return Center(
                  child: Text("Progress Error: ${progressSnapshot.error}"));
            }

            // Graceful Initialization
            Map<String, dynamic> progressData = {};
            if (progressSnapshot.hasData && progressSnapshot.data!.exists) {
              progressData =
                  progressSnapshot.data!.data() as Map<String, dynamic>;
            }

            final Map<String, dynamic> lessonProgressMap =
                (progressData['lessons'] as Map<String, dynamic>?) ?? {};

            return StreamBuilder<QuerySnapshot>(
              stream: lessonsRef.snapshots(),
              builder: (context, lessonSnapshot) {
                if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (lessonSnapshot.hasError) {
                  return Center(
                      child: Text('Lesson Error: ${lessonSnapshot.error}'));
                }
                if (lessonSnapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No lessons found for this module.'));
                }

                final lessons = lessonSnapshot.data!.docs;

                // Numerical Sorting
                lessons.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final int orderA =
                      (dataA['orderIndex'] as num?)?.toInt() ?? 999;
                  final int orderB =
                      (dataB['orderIndex'] as num?)?.toInt() ?? 999;
                  return orderA.compareTo(orderB);
                });

                if (_selectedIndex >= lessons.length) {
                  _selectedIndex = 0;
                }

                final selectedLesson = lessons[_selectedIndex];
                final selectedLessonData =
                    selectedLesson.data() as Map<String, dynamic>? ?? {};

                final unitTitle =
                    "Unit ${selectedLessonData['orderIndex'] ?? _selectedIndex + 1}";
                final lessonTitle = selectedLessonData['title'] ?? 'Lesson';

                // Call the Layout Widget from the new file
                return ViewUnitsLayout(
                  moduleTitle: moduleTitle,
                  unitTitle: unitTitle,
                  lessonTitle: lessonTitle,
                  lessons: lessons,
                  selectedIndex: _selectedIndex,
                  lessonProgressMap: lessonProgressMap,
                  moduleId: widget.moduleId,
                  roomId: widget.roomId,
                  userId: widget.userId,
                  onLessonTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}