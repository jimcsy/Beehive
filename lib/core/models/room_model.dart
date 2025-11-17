import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  // Properties that "mirror" your Firestore document
  final String id;        // This is the document ID (e.g., "7Y5L0E")
  final String className;
  final String createdBy;
  final String creatorId;
  final String roomCode;
  final String roomLink;
  final String section;
  final String subject;
  final Timestamp? createdAt; // Made nullable for creating new objects

  // Constructor
  RoomModel({
    required this.id,
    required this.className,
    required this.createdBy,
    required this.creatorId,
    required this.roomCode,
    required this.roomLink,
    required this.section,
    required this.subject,
    this.createdAt, // Optional in the constructor
  });

  // The "bridge" factory that builds your model FROM Firestore data
  factory RoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return RoomModel(
      id: doc.id,
      className: data['className'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorId: data['creatorId'] ?? '',
      roomCode: data['roomCode'] ?? '',
      roomLink: data['roomLink'] ?? '',
      section: data['section'] ?? '',
      subject: data['subject'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  // Method for converting our model TO a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'createdBy': createdBy,
      'creatorId': creatorId,
      'roomCode': roomCode,
      'roomLink': roomLink,
      'section': section,
      'subject': subject,
      // 'createdAt' will be added by the FirestoreService
    };
  }
}