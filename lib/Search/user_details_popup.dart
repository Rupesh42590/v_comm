import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_comm/Chat/chat_page.dart';

class UserDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPopup({super.key, required this.userData});

  void _navigateToChat(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String uid = userData['uid'] ?? userData['id'];

    List<String> ids = [currentUser.uid, uid];
    ids.sort();
    String chatRoomId = ids.join('_');

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(chatRoomId: chatRoomId, otherUser: userData),
      ),
    );
  }

  String? _convertGDriveLink(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.contains('drive.google.com/uc?export=view')) {
      return url;
    }

    final patterns = [
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.group(1) != null) {
        return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final String name = userData['name'] ?? 'No Name';
    final String email = userData['email'] ?? 'No Email';
    final String dept = userData['dept'] ?? 'N/A';
    final String customId = userData['customId'] ?? 'N/A';

    final String uid = userData['uid'] ?? userData['id'];
    final String? photoUrl = _convertGDriveLink(userData['photoUrl']);
    final String phoneNumber = userData['phone'] ?? '';

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

          // ✅ Image box fixed
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover, // ✅ fit image properly
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            return _imageFallback(name);
                          },
                        )
                      : _imageFallback(name),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 24);
                    final bool isOnline =
                        (snapshot.data!.data()
                            as Map<String, dynamic>?)?['online'] ??
                        false;
                    return _buildStatusIndicator(isOnline);
                  },
                ),

                Divider(color: Colors.white.withOpacity(0.2), height: 30),

                _buildDetailRow(Icons.email_outlined, email),
                if (phoneNumber.isNotEmpty) ...[
                  SizedBox(height: 12),
                  _buildDetailRow(Icons.phone_outlined, phoneNumber),
                ],
                SizedBox(height: 12),
                _buildDetailRow(Icons.business_center_outlined, dept),
                SizedBox(height: 12),
                _buildDetailRow(Icons.badge_outlined, "ID: $customId"),

                Divider(color: Colors.white.withOpacity(0.2), height: 30),

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

  Widget _imageFallback(String name) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

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
