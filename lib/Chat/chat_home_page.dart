import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:v_comm/Chat/chat_page.dart';
import 'package:v_comm/Search/search_page.dart';
import 'package:v_comm/Chat/create_group_page.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _navigateToChat(Map<String, dynamic> otherUser, String chatRoomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chatRoomId: chatRoomId, otherUser: otherUser),
      ),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                _buildOptionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: "New Solo Chat",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
                  },
                ),
                const SizedBox(height: 16),
                _buildOptionTile(
                  icon: Icons.group_add_outlined,
                  title: "New Group Chat",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        title: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16, fontWeight: FontWeight.w500)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
        title: Text("Chats", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100), // Adjust to sit above the Nav Bar
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: FloatingActionButton(
          onPressed: _showNewChatOptions,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Color(0xFF111111), Colors.black]),
        ),
        child: _buildChatsList(),
      ),
    );
  }

  Widget _buildChatsList() {
    if (currentUser == null) return const Center(child: Text("Please log in."));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: currentUser!.uid).orderBy('lastMessageTimestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("No conversations yet.\nTap the '+' button to start one.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: snapshot.data!.docs.map((doc) => _ChatListItem(chatDoc: doc, currentUser: currentUser!, onUserTap: _navigateToChat)).toList(),
        );
      },
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final DocumentSnapshot chatDoc;
  final User currentUser;
  final Function(Map<String, dynamic>, String) onUserTap;
  const _ChatListItem({required this.chatDoc, required this.currentUser, required this.onUserTap});

  @override
  Widget build(BuildContext context) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    if (chatData['lastMessageTimestamp'] == null) return const SizedBox.shrink();

    final bool isGroup = chatData['isGroup'] ?? false;
    
    if (isGroup) {
      final String groupName = chatData['groupName'] ?? 'Group Chat';
      final Timestamp? lastMessageTimestamp = chatData['lastMessageTimestamp'];
      final groupData = {'id': chatDoc.id, 'name': groupName, 'isGroup': true};
      
      return _buildCard(context, groupData, chatData, lastMessageTimestamp, onUserTap);
    } else {
      final otherUserId = (chatData['participants'] as List).firstWhere((id) => id != currentUser.uid, orElse: () => 'unknown');
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const SizedBox(height: 80);
          final otherUserData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final fullUserData = {'id': otherUserId, ...otherUserData};
          final Timestamp? lastMessageTimestamp = chatData['lastMessageTimestamp'];
          return _buildCard(context, fullUserData, chatData, lastMessageTimestamp, onUserTap);
        },
      );
    }
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> displayData, Map<String, dynamic> chatData, Timestamp? timestamp, Function(Map<String, dynamic>, String) onTap) {
    final String name = displayData['name'] ?? 'Chat';
    final String? photoUrl = displayData['photoUrl'];
    final bool isGroup = displayData['isGroup'] ?? false;
    
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTap(displayData, chatDoc.id),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? Icon(isGroup ? Icons.group : Icons.person, color: Colors.white54) : null,
          ),
          title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          subtitle: Text(chatData['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.grey.shade400)),
          trailing: Text(timestamp != null ? DateFormat('h:mm a').format(timestamp.toDate()) : '', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ),
    );
  }
}