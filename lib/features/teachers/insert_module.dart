import 'package:beehive/core/services/firestore_services.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NO LONGER NEEDED
import '../shared/show_modal.dart';

// --- 2. ADD IMPORTS ---
import 'package:provider/provider.dart';

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
  bool _isRoomNameLoading = true; // For loading the room name

  // --- 3. STORE THE SERVICE ---
  late FirestoreService _firestoreService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the service here (it's safer than initState)
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _fetchRoomName();
  }

  // --- 4. REFACTORED: Uses the service ---
  Future<void> _fetchRoomName() async {
    try {
      final roomDoc = await _firestoreService.rooms.getRoom(widget.roomCode);
      if (mounted) {
        setState(() {
          _roomName = roomDoc != null ? roomDoc.className : 'this room';
          _isRoomNameLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _roomName = 'this room';
          _isRoomNameLoading = false;
        });
      }
    }
  }

  // --- 5. DELETED: _getGlobalModule() ---
  // --- 6. DELETED: _moduleAlreadyInRoom() ---

  // --- 7. REFACTORED: _linkModule ---
  Future<void> _linkModule(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      // 1. Get the global module by its title
      final globalModule =
          await _firestoreService.modules.getGlobalModuleByTitle(widget.moduleTitle);

      if (globalModule == null) {
        showMessage(context, "❌ Global module not found.");
        return;
      }

      // 2. Check if it's already linked
      final alreadyLinked = await _firestoreService.modules.isModuleLinked(
          widget.roomCode, globalModule.id);

      if (alreadyLinked) {
        showMessage(context, "${widget.moduleTitle} is already linked.");
        return;
      }

      // 3. Link the module
      await _firestoreService.modules.linkModuleToRoom(widget.roomCode, globalModule);

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
        // 8. --- Added a loading check for the room name ---
        _isRoomNameLoading
            ? 'Loading...'
            : 'Do you want to link "${widget.moduleTitle}" to "${_roomName ?? 'this room'}"?',
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
                // 9. --- Disable button while loading room name OR saving ---
                onPressed: (_isSaving || _isRoomNameLoading)
                    ? null 
                    : () => _linkModule(context),
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