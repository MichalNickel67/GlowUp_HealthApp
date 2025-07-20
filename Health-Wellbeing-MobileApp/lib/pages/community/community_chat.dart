import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// A page that displays a community chat interface where users can send and view messages
class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key});

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sends a message to the community chat
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint("Message is empty!");
      }
      return; // Don't send empty messages
    }

    User? user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        debugPrint("No user is logged in!");
      }
      return; // Ensure user is logged in
    }

    try {
      // Get user details from the Firestore (UserDetails collection)
      if (kDebugMode) {
        debugPrint("Getting user details for UID: ${user.uid}");
      }
      DocumentSnapshot userDoc = await _firestore.collection('UserDetails').doc(user.uid).get();

      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint("User details not found in UserDetails collection");
        }
        return;
      }

      String userName = (userDoc.data() as Map<String, dynamic>)['name'] as String; // Fetch user's name from UserDetails

      if (kDebugMode) {
        debugPrint("User Name: $userName");
      }

      // Add message to the global community messages collection
      await _firestore.collection('CommunityChats').add({
        'userId': user.uid,
        'name': userName,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint("Message sent successfully!");
      }

      // Clear the message input after sending
      _messageController.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error sending message: $e"); // Catch any Firestore errors
      }
    }
  }

  // Deletes a message from the community chat
  Future<void> _deleteMessage(String messageId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Delete the message from Firestore
      await _firestore
          .collection('CommunityChats')
          .doc(messageId)
          .delete();

      if (kDebugMode) {
        debugPrint("Message deleted successfully!");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error deleting message: $e");
      }
    }
  }

  // Formats a Firestore timestamp to a readable date string
  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String hour = dateTime.hour.toString().padLeft(2, '0'); // Add leading zero for hour
    String minute = dateTime.minute.toString().padLeft(2, '0'); // Add leading zero for minute
    return "${dateTime.day}-${dateTime.month}-${dateTime.year} $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('CommunityChats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  if (kDebugMode) {
                    debugPrint("Error in StreamBuilder: ${snapshot.error}");
                  }
                  return Center(child: Text("Error loading chats: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet. Start the conversation!"));
                }
                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String messageId = doc.id;
                    // Check if this message belongs to the current user
                    bool isOwnMessage = false;
                    if (data.containsKey('userId') && _auth.currentUser != null) {
                      isOwnMessage = data['userId'] == _auth.currentUser!.uid;
                    }
                    final name = data['name'] ?? 'Unknown';
                    final message = data['message'] ?? 'No message content';
                    final timestamp = data['timestamp'] ?? Timestamp.now();

                    return _chatBubble(
                        name,
                        message,
                        timestamp,
                        messageId,
                        isOwnMessage
                    );
                  }).toList(),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Creates a chat bubble widget for a message
  Widget _chatBubble(String name, String message, Timestamp timestamp, String messageId, bool isOwnMessage) {
    String formattedTime = _formatDate(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOwnMessage ? Colors.blue.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 3),
          Text(message),
          const SizedBox(height: 5),
          Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (isOwnMessage)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteMessage(messageId);
              },
            ),
        ],
      ),
    );
  }

  // Builds the message input field and send button
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}