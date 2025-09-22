import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPassword extends StatelessWidget {
  final TextEditingController usernameController;
  const ForgotPassword(this.usernameController, {super.key});

  void _showFeedbackSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError
            ? Colors.redAccent.shade200.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        if (usernameController.text.trim().isEmpty) {
          _showFeedbackSnackBar(context, "Please enter your email to reset your password.");
          return;
        }
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(
            email: usernameController.text.trim(),
          );
          _showFeedbackSnackBar(context, "Password reset email sent. Check your inbox.", isError: false);
        } catch (e) {
          _showFeedbackSnackBar(context, "Failed to send reset email. Please try again.");
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text('Forgot Password?', style: GoogleFonts.inter()),
    );
  }
}