import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/teachers/notify_students.dart';

class NotificationTester extends StatefulWidget {
  const NotificationTester({super.key});

  @override
  State<NotificationTester> createState() => _NotificationTesterState();
}

class _NotificationTesterState extends State<NotificationTester> {
  final TextEditingController _studentIdController = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Notification Tester'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Test Notification System',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            const Text('Current User ID:'),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                FirebaseAuth.instance.currentUser?.uid ?? 'No user logged in',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID (or leave empty to use your own ID)',
                border: OutlineInputBorder(),
                hintText: 'Enter student Firebase UID',
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isSending ? null : _sendTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
              ),
              child: _isSending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Text('Sending...'),
                      ],
                    )
                  : const Text(
                      '🚀 Send Test Notification',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            
            const Divider(),
            const SizedBox(height: 10),
            
            const Text(
              '💡 Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text('• Leave Student ID empty to send to yourself'),
            const Text('• Check your console logs for debugging'),
            const Text('• Make sure the student has proper Firestore permissions'),
            const Text('• Check the student\'s notification page after sending'),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSending = true);
    
    try {
      String targetStudentId = _studentIdController.text.trim();
      
      // If no ID provided, use current user's ID
      if (targetStudentId.isEmpty) {
        targetStudentId = FirebaseAuth.instance.currentUser?.uid ?? '';
      }
      
      if (targetStudentId.isEmpty) {
        throw Exception('No valid student ID available');
      }
      
      await sendTestNotification(studentId: targetStudentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test notification sent to: $targetStudentId'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Test notification error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }
}