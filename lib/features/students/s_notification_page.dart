import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentNotificationPage extends StatefulWidget {
  const StudentNotificationPage({super.key});

  @override
  State<StudentNotificationPage> createState() => _StudentNotificationPageState();
}

class _StudentNotificationPageState extends State<StudentNotificationPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to view notifications.")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔹 Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 Error state
          if (snapshot.hasError) {
            debugPrint("❌ Notification error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text("Failed to load notifications"),
                  const SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          // 🔹 No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet 🎉",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll receive notifications when teachers\nupdate or delete rooms you\'ve joined.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a rebuild to refresh notifications
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final data = notifications[index].data() as Map<String, dynamic>?;
                
                // Handle potential null data
                if (data == null) {
                  return const SizedBox.shrink();
                }

                final title = data['title'] ?? 'Notification';
                final message = data['message'] ?? '';
                final createdAt = data['createdAt'] as Timestamp?;
                final isRead = data['read'] == true;
                final type = data['type'] ?? 'general';
                
                // Format timestamp
                String timeAgo = 'Just now';
                if (createdAt != null) {
                  final now = DateTime.now();
                  final notificationTime = createdAt.toDate();
                  final difference = now.difference(notificationTime);
                  
                  if (difference.inDays > 0) {
                    timeAgo = '${difference.inDays}d ago';
                  } else if (difference.inHours > 0) {
                    timeAgo = '${difference.inHours}h ago';
                  } else if (difference.inMinutes > 0) {
                    timeAgo = '${difference.inMinutes}m ago';
                  }
                }

                // Choose icon based on notification type
                IconData notificationIcon = Icons.notifications;
                Color iconColor = Colors.blue;
                
                switch (type) {
                  case 'room_deletion':
                    notificationIcon = Icons.delete_outline;
                    iconColor = Colors.red;
                    break;
                  case 'room_update':
                    notificationIcon = Icons.edit_outlined;
                    iconColor = Colors.orange;
                    break;
                  case 'test':
                    notificationIcon = Icons.bug_report;
                    iconColor = Colors.green;
                    break;
                  default:
                    notificationIcon = Icons.info_outline;
                    iconColor = Colors.blue;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: isRead ? 1 : 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(notificationIcon, color: iconColor),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: isRead
                        ? null
                        : const Icon(Icons.circle, color: Colors.blue, size: 10),
                    onTap: () async {
                      // Mark as read
                      try {
                        await notifications[index].reference.update({'read': true});
                        debugPrint('✅ Notification marked as read: ${notifications[index].id}');
                      } catch (e) {
                        debugPrint('❌ Failed to mark notification as read: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to mark notification as read'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}