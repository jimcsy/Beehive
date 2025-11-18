// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String birthday;
  
  // --- 1. THIS IS THE FIX ---
  // We make 'createdAt' nullable (with the '?')
  // This allows us to create a UserModel object in our code
  // *without* a 'createdAt' value.
  final Timestamp? createdAt; 

  String get fullName => '$firstName $lastName';

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    
    // --- 2. THIS IS THE OTHER PART OF THE FIX ---
    // We remove 'required' from 'this.createdAt'.
    // This makes it an optional parameter in the constructor.
    this.createdAt, 
  });

  // Factory 'bridge' for building a model FROM Firestore data
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '', 
      role: data['role'] ?? 'student',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      birthday: data['birthday'] ?? '',
      
      // We read it from Firestore as nullable, just in case
      createdAt: data['createdAt'] as Timestamp?, 
    );
  }

  // Method for converting our model TO a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday,
      
      // We DON'T include 'createdAt' here.
      // Our FirestoreService will add 'FieldValue.serverTimestamp()'
      // when it saves the user to the database.
    };
  }
}