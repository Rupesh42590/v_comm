import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatelessWidget {
  final TextEditingController usernameController;
  const ForgotPassword(this.usernameController, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(
            email: usernameController.text,
          );
          print("Password reset email sent to ${usernameController.text}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Password reset email sent. Please check your inbox or Spam folder.",
              ),
              backgroundColor: Colors.white.withOpacity(0.1),
              duration: Duration(seconds: 4),
            ),
          );
        } on FirebaseAuthException catch (e) {
          print("FirebaseAuthException message: ${e.code}");
        } catch (e) {
          print("Error: $e");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white70,
          ),
        ),
      ),
    );
  }
}
