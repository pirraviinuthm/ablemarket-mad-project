import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; // Import the Chat Screen

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect Dark Mode for better CircleAvatar styling
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Support Messages'),
        backgroundColor: Colors.blue, // CHANGED TO BLUE
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue)); // CHANGED TO BLUE
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No messages yet"));
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  // CHANGED TO BLUE SHADES
                  backgroundColor: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                  child: const Icon(Icons.person, color: Colors.blue), // CHANGED TO BLUE
                ),
                title: Text(data['userName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  data['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  // Navigate to Chat Screen as ADMIN
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: data['userId'], // Chatting with this user
                        otherUserName: data['userName'] ?? 'User',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}