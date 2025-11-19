import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This function updates the specific lesson key in the map to TRUE
  Future<void> markLessonAsCompleted({
    required String moduleId, // e.g., "module1"
    required String lessonId, // e.g., "M01-L03"
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Reference to: users -> [USER_ID] -> progress -> [module1]
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(moduleId);

      // 🌟 THE MAGIC: Use "Dot Notation" to update a nested field
      // "lessons.M01-L03" : true
      await docRef.update({
        'lessons.$lessonId': true, 
      });
      
      print("✅ Success: $lessonId marked as true in $moduleId");
      
    } catch (e) {
      print("❌ Error updating progress: $e");
      // Optional: If the document doesn't exist yet, create it
      // _createInitialProgressDoc(user.uid, moduleId, lessonId);
    }
  }
}