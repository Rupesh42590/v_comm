import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpButton extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  const SignUpButton(
    this.usernameController,
    this.passwordController, {
    super.key,
  });

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () async {
        final email = usernameController.text.trim();
        final password = passwordController.text.trim();

        if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Enter email and password")),
          );
          return;
        }

        try {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          debugPrint("User signed up: ${credential.user?.email}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signed up: ${credential.user?.email}")),
          );
        } on FirebaseAuthException catch (e) {
          debugPrint("Sign up error: ${e.code} - ${e.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sign up failed: ${e.message}")),
          );
        }
      },

      child: Text(
        'Sign Up',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
