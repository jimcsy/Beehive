import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModuleProgressPage extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String roomId;
  final String moduleId;
  final String moduleTitle;

  const StudentModuleProgressPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.roomId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Construct the Unique ID to find the specific progress doc
    final String uniqueProgressId = '${roomId}_$moduleId';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              studentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "Progress: $moduleTitle",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA0701F), Color(0xFFE8A319)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 2. Stream the Student's Progress Document
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('progress')
            .doc(uniqueProgressId)
            .snapshots(),
        builder: (context, progressSnapshot) {
          if (progressSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = progressSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          
          // 1. FETCH DATA MAPS
          final Map<String, dynamic> completedLessonsMap = data['lessons'] ?? {};
          final Map<String, dynamic> quizScores = data['quizScores'] ?? {};
          final Map<String, dynamic> quizAttempts = data['quizAttempts'] ?? {};
          final Map<String, dynamic> quizTotals = data['quizTotal'] ?? {};

          // 3. Stream the Module's Lessons to compare against
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('modules')
                .doc(moduleId)
                .collection('lessons')
                .snapshots(),
            builder: (context, lessonSnapshot) {
              if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!lessonSnapshot.hasData || lessonSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No lessons found in this module."));
              }

              // Sort lessons by ID
              final lessons = lessonSnapshot.data!.docs;
              lessons.sort((a, b) => a.id.compareTo(b.id));

              // Calculate Stats
              final int totalLessons = lessons.length;
              int completedCount = 0;
              completedLessonsMap.forEach((key, value) {
                if (value == true) completedCount++;
              });

              final double progressPercent = totalLessons > 0 ? (completedCount / totalLessons) : 0.0;

              return Column(
                children: [
                  // --- SCORE HEADER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: progressPercent,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA0701F)),
                              ),
                            ),
                            Text(
                              "${(progressPercent * 100).toInt()}%",
                              style: const TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold, 
                                color: Color(0xFFA0701F)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "$completedCount / $totalLessons Completed",
                          style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // --- LESSON LIST ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final lessonId = lesson.id;
                        final lessonData = lesson.data() as Map<String, dynamic>;
                        final String title = lessonData['title'] ?? 'Lesson ${index + 1}';
                        final String category = lessonData['category'] ?? '';
                        
                        final bool isCompleted = completedLessonsMap[lessonId] == true;

                        // 2. PREPARE SUBTITLE (Show score if quiz)
                        String subtitleText;
                        if (category == 'quiz' && isCompleted) {
                          final score = quizScores[lessonId] ?? 0;
                          final total = quizTotals[lessonId] ?? '?';
                          subtitleText = "Score: $score / $total";
                        } else {
                          subtitleText = isCompleted ? "Completed" : "Not Started / In Progress";
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          color: isCompleted ? Colors.green[50] : Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCompleted ? Colors.green : Colors.grey[300]!
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCompleted ? Icons.check : Icons.lock_clock,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green[900] : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isCompleted ? Colors.green[700] : Colors.grey[600],
                                fontWeight: (category == 'quiz' && isCompleted) ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              // 3. SHOW DIALOG FOR QUIZ DETAILS
                              if (category == 'quiz' && isCompleted) {
                                final attempts = quizAttempts[lessonId] ?? 1;
                                final score = quizScores[lessonId] ?? 0;
                                
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(title, textAlign: TextAlign.center),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Divider(),
                                        ListTile(
                                          leading: const Icon(Icons.star, color: Colors.amber),
                                          title: const Text("Best Score"),
                                          trailing: Text("$score", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.refresh, color: Colors.blue),
                                          title: const Text("Attempts Used"),
                                          trailing: Text("$attempts", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context), 
                                        child: const Text("Close")
                                      )
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}