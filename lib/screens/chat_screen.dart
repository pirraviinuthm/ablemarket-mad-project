import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId; // If Admin views, this is the User's ID. If User views, this is 'admin'.
  final String otherUserName;
  final String? initialMessage; 

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late String chatId;
  
  // Dynamic Theme Color variable
  late Color themeColor;

  @override
  void initState() {
    super.initState();
    
    // --- 1. DETERMINE ROLE & COLOR ---
    // If I am chatting with 'admin', I am a User (Green).
    // If I am chatting with anyone else, I am the Admin (Blue).
    bool amIAdmin = widget.otherUserId != 'admin';
    
    // Set color based on Role
    themeColor = amIAdmin ? Colors.blue : const Color(0xFF2E7D32);

    // --- 2. DETERMINE CHAT ID ---
    if (widget.otherUserId == 'admin') {
       chatId = currentUser!.uid; // User chatting with Admin
    } else {
       chatId = widget.otherUserId; // Admin chatting with User
    }

    // --- 3. SEND INITIAL MESSAGE ---
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    // Add message to sub-collection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the Chat Summary (for List view)
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': messageText,
      'lastTime': FieldValue.serverTimestamp(),
      'userName': widget.otherUserId == 'admin' ? (currentUser!.email ?? 'User') : widget.otherUserName, 
      'userId': chatId,
    }, SetOptions(merge: true));
    
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: themeColor), // Dynamic Icon Color
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
        backgroundColor: themeColor, // Dynamic AppBar Color
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Show newest at bottom
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['senderId'] == currentUser!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          // Dynamic Bubble Color: My Color vs Grey
                          color: isMe ? themeColor : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: themeColor, // Dynamic Button Color
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}