import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ADD THIS IMPORT
import 'package:url_launcher/url_launcher.dart';
import 'package:v_comm/LoginPage/login_page.dart';
import 'package:v_comm/Profile/edit_profile.dart';
import 'package:v_comm/Profile/notification_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // --- (Helper functions remain the same) ---
  void _showFeedbackSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError
            ? Colors.redAccent.shade200.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    // This outer StreamBuilder handles the user's login state (Auth).
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginPage();
        }

        final user = authSnapshot.data!;

        // MODIFICATION: This new, inner StreamBuilder listens for real-time data changes in Firestore.
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, firestoreSnapshot) {
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    "User data not found.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            // Get user data from the Firestore snapshot.
            final userData =
                firestoreSnapshot.data!.data() as Map<String, dynamic>;
            final String name =
                userData['name'] ?? user.displayName ?? "User Name";
            final String email = userData['email'] ?? "no-email@example.com";
            final String? photoUrl =
                userData['photoUrl']; // This is the real-time photo URL.

            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: const Color(0xFF1A1A1A),
                elevation: 0,
                shape: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  "Profile",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Color(0xFF111111), Colors.black],
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // MODIFICATION: The CircleAvatar now uses the real-time photoUrl from Firestore.
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white54,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // MODIFICATION: Displays the name from Firestore.
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    email,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSectionHeader("Account"),
                      _settingsTile(
                        icon: Icons.edit_outlined,
                        title: "Edit Profile",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                        },
                      ),
                      _settingsTile(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        onTap: () async {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );
                            _showFeedbackSnackBar(
                              context,
                              "Password reset email sent to $email.",
                              isError: false,
                            );
                          } catch (e) {
                            _showFeedbackSnackBar(
                              context,
                              "Failed to send email. Please try again.",
                            );
                          }
                        },
                      ),
                      _settingsTile(
                        icon: Icons.notifications_outlined,
                        title: "Notification Settings",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationSettingsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildSectionHeader("Support & Legal"),
                      _settingsTile(
                        icon: Icons.help_outline,
                        title: "Support",
                        onTap: () => _launchUrl(
                          'mailto:support@vcomm.com?subject=Support Request',
                        ),
                      ),
                      _settingsTile(
                        icon: Icons.description_outlined,
                        title: "Terms of Service",
                        onTap: () =>
                            _launchUrl('https://www.yourapp.com/terms'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.15),
                              foregroundColor: Colors.red.shade300,
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Logout",
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 16),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
        title: Text(
          title,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
