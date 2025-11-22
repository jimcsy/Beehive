import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> markLessonAsCompleted({
    required String roomId,   // 👈 NEW REQUIREMENT
    required String moduleId,
    required String lessonId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 🌟 FIX: Use the Composite ID (RoomID_ModuleID)
      final uniqueProgressId = '${roomId}_$moduleId';

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(uniqueProgressId); // 👈 UPDATED

      // Use set with merge
      await docRef.set({
        'lessons': {lessonId: true},
        'roomId': roomId, // Good for debugging later
        'moduleId': moduleId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Success: $lessonId marked as true in $uniqueProgressId");
    } catch (e) {
      print("❌ Error updating progress: $e");
    }
  }

  Future<void> saveQuizResult({
    required String roomId,
    required String moduleId,
    required String lessonId,
    required int score,
    required int totalQuestions,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final uniqueProgressId = '${roomId}_$moduleId';
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(uniqueProgressId);

      // 1. Get current data to check attempts
      final docSnap = await docRef.get();
      int currentAttempts = 0;
      int previousBest = 0;

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        final attemptsMap = data['quizAttempts'] as Map<String, dynamic>? ?? {};
        final scoresMap = data['quizScores'] as Map<String, dynamic>? ?? {};
        
        currentAttempts = attemptsMap[lessonId] ?? 0;
        previousBest = scoresMap[lessonId] ?? 0;
      }

      // 2. Logic: Increment attempt, keep best score
      final int newAttempts = currentAttempts + 1;
      final int bestScore = (score > previousBest) ? score : previousBest;

      // 3. Save to Firestore
      await docRef.set({
        'lessons': {lessonId: true}, // Mark as done
        'quizScores': {lessonId: bestScore}, // Save best score
        'quizTotal': {lessonId: totalQuestions}, // Save total questions for reference
        'quizAttempts': {lessonId: newAttempts}, // Save attempts count
        'roomId': roomId,
        'moduleId': moduleId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Quiz Saved: Score $score/$totalQuestions, Attempt #$newAttempts");
    } catch (e) {
      print("❌ Error saving quiz: $e");
    }
  }
}