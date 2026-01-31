import 'package:flutter/material.dart';
import 'chat_screen.dart'; // <--- IMPORT THE CHAT SCREEN

class UserProfileCenter extends StatelessWidget {
  const UserProfileCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for issues...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 30),
            _buildFAQTile('How to track my order?', 'Go to My Orders and click on the specific order to see the status.'),
            _buildFAQTile('How to return an item?', 'Contact the seller directly through the chat..'),
            _buildFAQTile('Payment failed what do I do?', 'Check your internet connection or try a different payment method.'),
            
            const SizedBox(height: 30),
            
            // --- UPDATED CHAT BUTTON ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(
                      otherUserId: 'admin',
                      otherUserName: 'Support Admin',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}