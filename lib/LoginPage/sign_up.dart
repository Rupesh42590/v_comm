import 'package:flutter/material.dart';

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        child: Text(
          'Sign Up',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
