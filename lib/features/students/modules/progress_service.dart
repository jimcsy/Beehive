import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> markLessonAsCompleted({
    required String moduleId,
    required String lessonId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(moduleId);

      // Use set with merge so the document is created if missing and we only update the nested field
      await docRef.set({
        'lessons': {lessonId: true}
      }, SetOptions(merge: true));

      print("✅ Success: $lessonId marked as true in $moduleId");
    } catch (e) {
      print("❌ Error updating progress: $e");
    }
  }
}
