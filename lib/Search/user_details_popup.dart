import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_comm/Chat/chat_page.dart'; // Import your chat page

class UserDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPopup({super.key, required this.userData});

  void _navigateToChat(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> ids = [currentUser.uid, userData['id']];
    ids.sort();
    String chatRoomId = ids.join('_');

    Navigator.pop(context); // Close the modal before navigating
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(chatRoomId: chatRoomId, otherUser: userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = userData['name'] ?? 'No Name';
    final String email = userData['email'] ?? 'No Email';
    final String dept = userData['dept'] ?? 'N/A';
    final String customId = userData['customId'] ?? 'N/A';
    final String? photoUrl = userData['photoUrl'];
    final String phoneNumber = userData['phoneNumber'] ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white54,
                            ),
                      )
                    : Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          // --- MODIFICATION: Redesigned Content Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Left-align the content
              children: [
                // --- Primary Info ---
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userData['id'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 24);
                    final bool isOnline =
                        (snapshot.data!.data()
                            as Map<String, dynamic>)['isOnline'] ??
                        false;
                    return _buildStatusIndicator(isOnline);
                  },
                ),

                // --- Divider ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    height: 1,
                  ),
                ),

                // --- Detail Rows with Icons ---
                _buildDetailRow(Icons.email_outlined, email),
                if (phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.phone_outlined, phoneNumber),
                ],
                const SizedBox(height: 12),
                _buildDetailRow(Icons.business_center_outlined, dept),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.badge_outlined, "ID: $customId"),

                // --- Divider ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    height: 1,
                  ),
                ),

                // --- Chat Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToChat(context),
                    icon: const Icon(Icons.message_outlined, size: 20),
                    label: const Text("Chat"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the Online/Offline status indicator
  Widget _buildStatusIndicator(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.15)
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: isOnline ? Colors.greenAccent.shade400 : Colors.grey,
            size: 10,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? "Online" : "Offline",
            style: GoogleFonts.inter(
              color: isOnline ? Colors.greenAccent.shade400 : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for creating consistent detail rows with icons
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
