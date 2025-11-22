// lib/core/models/recent_module_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentModuleModel {
  final String roomId;
  final String moduleId;

  RecentModuleModel({required this.roomId, required this.moduleId});

  factory RecentModuleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return RecentModuleModel(
      roomId: data['roomId'] ?? '',
      moduleId: data['moduleId'] ?? '',
    );
  }
}