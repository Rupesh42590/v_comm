import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:v_comm/HomePage/homepage.dart';

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
          final email = usernameController.text.trim();
          final password = passwordController.text.trim();

          UserCredential credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);

          User? user=credential.user;
          print(user?.displayName);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
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
