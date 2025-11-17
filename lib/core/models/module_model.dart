// lib/core/models/module_model.dart
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp, DocumentSnapshot;

class ModuleModel {
  final String id;
  final String description;
  final Timestamp? createdAt;
  final String title;
  // This model will also contain the 'lessons' subcollection

  ModuleModel({
    required this.id,
    required this.description,
    this.createdAt,
    required this.title,
  });

  factory ModuleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ModuleModel(
      id: doc.id,
      description: data['description'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      title: data['title'] ?? 'Untitled Module',
    );
  }
}