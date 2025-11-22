import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/core/models/room_model.dart';
import 'package:beehive/features/teachers/notify_students.dart'; // <-- Import the notification function
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------
// 1. ARCHIVED ROOMS LIST PAGE (StatelessWidget - Accessed via AppBar button)
// -----------------------------------------------------------
class ArchivedRoomsPage extends StatelessWidget {
  const ArchivedRoomsPage({super.key});

  // Helper method to handle unarchiving the room (Requires service for the update)
  Future<void> _unarchiveRoom(BuildContext context, FirestoreService firestoreService, String roomId, String className) async {
    // ... (Unarchive logic remains the same) ...
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unarchive Room'),
        content: Text('Are you sure you want to unarchive "$className"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unarchive', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await firestoreService.rooms.unarchiveRoom(roomId); 
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Room "$className" is now active.')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to unarchive: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final currentUserId = firestoreService.auth.currentUser?.uid ?? ''; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Rooms'),
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: firestoreService.rooms.getArchivedTeacherRoomsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error loading archived rooms: ${snapshot.error}'));
          }

          final archivedRooms = snapshot.data ?? [];

          if (archivedRooms.isEmpty) {
            return const Center(child: Text('You have no archived rooms.'));
          }

          return ListView.builder(
            itemCount: archivedRooms.length,
            itemBuilder: (context, index) {
              final room = archivedRooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(room.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Subject: ${room.subject}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.unarchive, color: Colors.blue),
                    tooltip: 'Unarchive Room',
                    onPressed: () => _unarchiveRoom(context, firestoreService, room.id, room.className),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// 2. ARCHIVE ROOM ACTION PAGE (StatefulWidget - Accessed via Room Card Modal)
// -----------------------------------------------------------
class ArchiveRoomPage extends StatefulWidget { 
  final String roomId;
  final String className; 
  final String subject; // <--- NEW PARAMETER
  final String teacherName; // <--- NEW PARAMETER (Passed from homepage)
  
  const ArchiveRoomPage({
    super.key, 
    required this.roomId, 
    required this.className,
    required this.subject, // <--- REQUIRED
    required this.teacherName, // <--- REQUIRED
  });

  @override
  State<ArchiveRoomPage> createState() => _ArchiveRoomPageState();
}

class _ArchiveRoomPageState extends State<ArchiveRoomPage> {
  
  Future<void> _showArchiveConfirmation() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Archive'),
        content: Text('Are you absolutely sure you want to archive the room "${widget.className}"? This will hide it from students.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive', style: TextStyle(color: Color(0xFFE8A319))),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        // 1. NOTIFY STUDENTS BEFORE ARCHIVING
        await notifyStudentsOnRoomArchive(
            className: widget.className,
            subject: widget.subject,
            roomId: widget.roomId,
            teacherName: widget.teacherName,
            firestoreService: firestoreService,
        );
        
        // 2. ARCHIVE THE ROOM (Database update)
        await firestoreService.rooms.archiveRoom(widget.roomId); 

        if(mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Room "${widget.className}" archived successfully, and students have been notified.'),
          ));
          Navigator.pop(context); 
        }
      } catch (e) {
        if(mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Failed to archive room: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archive ${widget.className}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.archive, size: 64, color: Color(0xFFE8A319)),
              const SizedBox(height: 20),
              Text(
                'Archiving the room "${widget.className}" will hide it from active students. You can unarchive it later.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _showArchiveConfirmation,
                icon: const Icon(Icons.archive),
                label: const Text('Confirm Archive Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A319),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}