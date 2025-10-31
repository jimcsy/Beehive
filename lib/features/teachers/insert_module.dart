import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/show_modal.dart';

class InsertModule extends StatefulWidget {
  final String roomCode;
  final String moduleTitle;
  final String moduleDescription;

  const InsertModule({
    super.key,
    required this.roomCode,
    required this.moduleTitle,
    required this.moduleDescription,
  });

  @override
  State<InsertModule> createState() => _InsertModuleState();
}

class _InsertModuleState extends State<InsertModule> {
  bool _isSaving = false;
  String? _roomName;

  @override
  void initState() {
    super.initState();
    _fetchRoomName();
  }

  Future<void> _fetchRoomName() async {
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .get();

      setState(() {
        _roomName = roomDoc.exists ? roomDoc['className'] ?? 'this room' : 'this room';
      });
    } catch (_) {
      setState(() => _roomName = 'this room');
    }
  }

  Future<DocumentSnapshot?> _getGlobalModule() async {
    final query = await FirebaseFirestore.instance
        .collection('modules')
        .where('title', isEqualTo: widget.moduleTitle)
        .limit(1)
        .get();
    return query.docs.isNotEmpty ? query.docs.first : null;
  }

  Future<bool> _moduleAlreadyInRoom(String moduleId) async {
    final doc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('modules')
        .doc(moduleId)
        .get();
    return doc.exists;
  }

  Future<void> _linkModule(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      final globalModule = await _getGlobalModule();
      if (globalModule == null) {
        showMessage(context, "❌ Global module not found.");
        return;
      }

      final globalModuleId = globalModule.id;
      final already = await _moduleAlreadyInRoom(globalModuleId);

      if (already) {
        showMessage(context, "${widget.moduleTitle} already linked.");
        return;
      }

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('modules')
          .doc(globalModuleId)
          .set({
        'title': globalModule['title'],
        'description': globalModule['description'],
        'globalRef': FirebaseFirestore.instance
            .collection('modules')
            .doc(globalModuleId)
            .path,
        'linkedAt': FieldValue.serverTimestamp(),
      });

      showMessage(context, "${widget.moduleTitle} linked to $_roomName!");

    } catch (e) {
      showMessage(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Link Module',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Do you want to link "${widget.moduleTitle}" to "${_roomName ?? 'this room'}"?',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFFA27221)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                child: const Text('No'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _linkModule(context),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 235, 200, 95)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                child: const Text('Yes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
