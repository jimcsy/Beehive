import 'package:beehive/features/teachers/insert_module.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Function to show room selection and navigate to InsertModule
  Future<void> _showUploadOptions({
  required String moduleTitle,
  required String moduleDescription,
}) async {
  try {
    final snapshot = await _firestore
        .collection('rooms')
        .where('creatorId', isEqualTo: currentUserId)
        .get();

    if (snapshot.docs.isEmpty) {
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
        isScrollControlled: true, // enables flexible height
        enableDrag: false, // ❌ disables sliding
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return SizedBox(
            height: screenHeight * 0.75, // ✅ fixed 3/4 of screen height
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      child: ListView.builder(
                        itemCount: snapshot.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.docs[index].data();
                          return ListTile(
                            leading: const Icon(Icons.meeting_room_outlined),
                            title: Text(data['className'] ?? 'Unnamed Room', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),),
                            subtitle: Text(
                                '${data['section'] ?? ''} - ${data['subject'] ?? ''}',style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),),
                            onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.2), // optional dim background
                              builder: (context) => InsertModule(
                                roomCode: data['roomCode'],
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

  // Function to show modal bottom sheet menu
  void _showModuleOptions({
    required String moduleTitle,
    required String moduleDescription,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true, // closes when tapping outside
      enableDrag: false, // no slide to close
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        
        stream: _firestore.collection('modules').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No modules found.'));
          }

          final modules = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Python',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Simple is better than complex.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 10),

              ...modules.map((doc) {
                final module = doc.data() as Map<String, dynamic>;
                final moduleTitle = module['title'] ?? 'Untitled Module';
                final moduleDescription =
                    module['description'] ?? 'No description available';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    height: 75,
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              moduleTitle,
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
