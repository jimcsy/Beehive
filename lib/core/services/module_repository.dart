import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/core/models/module_model.dart';
import 'package:beehive/core/models/lesson_module.dart';

class ModuleRepository {
  final FirebaseFirestore _db;
  ModuleRepository(this._db);

  Stream<List<ModuleModel>> getGlobalModulesStream() {
    return _db.collection('modules').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ModuleModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Stream<List<String>> getLinkedModuleIdsStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('modules')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Stream<List<ModuleModel>> getModulesByIdsStream(List<String> moduleIds) {
    if (moduleIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('modules')
        .where(FieldPath.documentId, whereIn: moduleIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModuleModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Stream<List<LessonModel>> getActiveLessonsStream(String moduleId) {
    return _db
        .collection('modules')
        .doc(moduleId)
        .collection('lessons')
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LessonModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> archiveLesson(String moduleId, String lessonId) async {
    try {
      await _db
          .collection('modules')
          .doc(moduleId)
          .collection('lessons')
          .doc(lessonId)
          .update({'isArchived': true});
    } catch (e) {
      print('Error archiving lesson: $e');
      rethrow;
    }
  }

  Future<ModuleModel?> getGlobalModuleByTitle(String title) async {
    try {
      final query = await _db
          .collection('modules')
          .where('title', isEqualTo: title)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return ModuleModel.fromFirestore(
            query.docs.first as DocumentSnapshot<Map<String, dynamic>>);
      }
    } catch (e) {
      print('Error getting module by title: $e');
    }
    return null;
  }

  Future<bool> isModuleLinked(String roomId, String moduleId) async {
    try {
      final doc = await _db
          .collection('rooms')
          .doc(roomId)
          .collection('modules')
          .doc(moduleId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking module link: $e');
      return false;
    }
  }

  Future<void> linkModuleToRoom(String roomId, ModuleModel module) async {
    try {
      final linkData = {
        'title': module.title,
        'description': module.description,
        'globalRef': _db.collection('modules').doc(module.id).path,
        'linkedAt': FieldValue.serverTimestamp(),
      };
      await _db
          .collection('rooms')
          .doc(roomId)
          .collection('modules')
          .doc(module.id)
          .set(linkData);
    } catch (e) {
      print('Error linking module: $e');
      rethrow;
    }
  }

  
}