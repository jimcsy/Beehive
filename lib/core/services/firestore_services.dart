// lib/core/services/firestore_service.dart

import 'package:beehive/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Create a private instance of Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // This is the function we moved from your widget!
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching user: $e'); // Use a real logger in production
    }
    return null;
  }

  // Creates a new user document in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      // Get the Map from the model's toJson method
      final userMap = user.toJson();
      
      // Add the server timestamp here, NOT in the model
      userMap['createdAt'] = FieldValue.serverTimestamp(); 
      
      // Set the document
      await _db.collection('users').doc(user.uid).set(userMap);
    } catch (e) {
      print('Error creating user: $e');
      // Re-throw the error to be handled by the UI
      rethrow;
    }
  }
}