import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For Clipboard

// IMPORT THE NEW PAGE
import 'module_student_list.dart';

class ViewRoomPage extends StatelessWidget {
  final String roomId;
  final String className;
  final String subject;

  const ViewRoomPage({
    super.key,
    required this.roomId,
    required this.className,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          className,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA0701F), Color(0xFFE8A319)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    "Room Info",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Class Code: $roomId", style: const TextStyle(fontSize: 12,),),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          final link = "https://beehiveapp.page.link/$roomId";
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Link copied to clipboard!", style: TextStyle(fontSize: 12,),)),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy Join Link", style: TextStyle(fontSize: 12,),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA0701F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('modules')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('No modules have been uploaded to this room yet.', textAlign: TextAlign.center,),
                    ),
                  );
                }

                final modules = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    // Get Document ID and Data
                    final moduleId = modules[index].id; 
                    final module = modules[index].data() as Map<String, dynamic>;
                    
                    final title = module['title'] ?? 'Untitled Module';
                    final description = module['description'] ?? 'No description available.';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.menu_book, color: Color(0xFFA0701F)),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          description,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        // --- NAVIGATION LOGIC ADDED HERE ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModuleStudentListPage(
                                roomId: roomId,
                                moduleId: moduleId,
                                moduleTitle: title,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}