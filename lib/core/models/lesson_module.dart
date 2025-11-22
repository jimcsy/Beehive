// lib/core/models/lesson_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String category;
  final Timestamp? createdAt;
  final String title;
  
  // --- ADDED THESE FIELDS ---
  final String description;
  final bool isArchived;

  LessonModel({
    required this.id,
    required this.category,
    this.createdAt,
    required this.title,
    required this.description,
    required this.isArchived,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LessonModel(
      id: doc.id,
      category: data['category'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      title: data['title'] ?? 'Untitled Lesson',
      
      // --- ADDED THESE MAPPINGS ---
      description: data['description'] ?? '',
      isArchived: data['isArchived'] ?? false, 
    );
  }
}