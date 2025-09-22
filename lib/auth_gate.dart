import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:v_comm/HomePage/homepage.dart';
import 'package:v_comm/LoginPage/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // --- THIS IS THE FIX ---
            // Get the User object from the snapshot's data
            final user = snapshot.data;

            // Pass the user object to the Homepage constructor
            return Homepage(user: user);
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
