import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInButton extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  const SignInButton(
    this.usernameController,
    this.passwordController, {
    super.key,
  });

  @override
  Widget build(context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
        elevation: 4,
      ),
      onPressed: () async {

        try {
          print("Sign In button pressed");
          final email = usernameController.text.trim();
          final password = passwordController.text.trim();

          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(" Signed in successfully")),
          );
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(" ${e.message}")));
        }
      },

      child: const Text(
        'Sign In',
        style: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
    );
  }
}
