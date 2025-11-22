import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/teachers/insert_module.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NO LONGER NEEDED
// import 'package:firebase_auth/firebase_auth.dart'; // <-- 2. NO LONGER NEEDED

// --- 3. ADD IMPORTS ---
import 'package:provider/provider.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/module_model.dart';

class ModulesPage extends StatefulWidget {
  // --- 4. ACCEPT THE USER MODEL ---
  final UserModel userModel;
  const ModulesPage({super.key, required this.userModel});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  // --- 5. REMOVED DIRECT DB/AUTH INSTANCES ---
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // --- 6. REFACTORED: Uses FirestoreService ---
  Future<void> _showUploadOptions({
    required String moduleTitle,
    required String moduleDescription,
  }) async {
    // Get the service from Provider
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      // Get the teacher's rooms using their UID
      final rooms = await firestoreService.rooms.getTeacherRooms(widget.userModel.uid);

      if (rooms.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('No Existing Rooms'),
              content: Text('You don’t have any existing rooms yet.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        final screenHeight = MediaQuery.of(context).size.height;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          enableDrag: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return SizedBox(
              height: screenHeight * 0.75,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Your modal title/divider UI is unchanged) ...
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
                          child: Text(
                            'Select a Room',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        // --- 7. USE THE CLEAN List<RoomModel> ---
                        child: ListView.builder(
                          itemCount: rooms.length, // Use the clean list
                          itemBuilder: (context, index) {
                            final room = rooms[index]; // 'room' is a RoomModel
                            return ListTile(
                              leading: const Icon(Icons.meeting_room_outlined),
                              title: Text(
                                room.className, // <-- Use model property
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${room.section} - ${room.subject}', // <-- Use model properties
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(0.2),
                                  builder: (context) => InsertModule(
                                    roomCode: room.roomCode, // <-- Use model property
                                    moduleTitle: moduleTitle,
                                    moduleDescription: moduleDescription,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
    }
  }

  // This function is UI-only, no major change needed
  void _showModuleOptions({
    required String moduleTitle,
    required String moduleDescription,
  }) {
    showModalBottomSheet(
      context: context,
      // ... (rest of your modal properties) ...
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showUploadOptions(
                    moduleTitle: moduleTitle,
                    moduleDescription: moduleDescription,
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.upload_outlined, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      "Upload Module",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // --- 8. REFACTORED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Get the service from Provider
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<ModuleModel>>( // <-- Use clean model
        stream: firestoreService.modules.getGlobalModulesStream(), // <-- Use service
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return const Center(child: Text('Error loading modules.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) { // <-- .docs REMOVED
            return const Center(child: Text('No modules found.'));
          }

          // 'modules' is now a clean List<ModuleModel>
          final modules = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ... (Your "Python" header text) ...
              const Text(
                'Python',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Simple is better than complex.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 10),

              // --- 9. USE THE CLEAN List<ModuleModel> ---
              ...modules.map((module) { // 'module' is a ModuleModel
                final moduleTitle = module.title;
                final moduleDescription = module.description;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    height: 75,
                    child: Card(
                      // ... (Your card UI is unchanged) ...
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              moduleTitle, // <-- Use clean property
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                _showModuleOptions(
                                  moduleTitle: moduleTitle,
                                  moduleDescription: moduleDescription,
                                );
                              },
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}