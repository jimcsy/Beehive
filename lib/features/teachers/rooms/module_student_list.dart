import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. IMPORT THE NEW PAGE
import 'student_module_progress.dart';

class ModuleStudentListPage extends StatelessWidget {
  final String roomId;
  final String moduleId;
  final String moduleTitle;

  const ModuleStudentListPage({
    super.key,
    required this.roomId,
    required this.moduleId,
    required this.moduleTitle,
  });

  Future<List<Map<String, dynamic>>> _fetchUserDetails(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final List<Map<String, dynamic>> usersData = [];

    for (var i = 0; i < userIds.length; i += 10) {
      final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      final chunk = userIds.sublist(i, end);

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          data['uid'] = doc.id;
          usersData.add(data);
        }
      } catch (e) {
        debugPrint("Error fetching user chunk: $e");
      }
    }
    return usersData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Students",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              moduleTitle,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('members')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No students have joined this room yet."));
          }

          final List<String> studentIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUserDetails(studentIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final students = userSnapshot.data ?? [];

              if (students.isEmpty) {
                return const Center(child: Text("Could not load student details."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  
                  final String firstName = student['firstName'] ?? '';
                  final String lastName = student['lastName'] ?? '';
                  final String fullName = student['fullName'] ?? '$firstName $lastName'.trim();
                  final String displayName = fullName.isNotEmpty ? fullName : 'Unknown Student';
                  final String email = student['email'] ?? 'No email';
                  final String studentId = student['uid']; 

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFA0701F),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(email),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      
                      // 2. ADD NAVIGATION HERE
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentModuleProgressPage(
                              studentId: studentId,
                              studentName: displayName,
                              roomId: roomId,
                              moduleId: moduleId,
                              moduleTitle: moduleTitle,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}