// ignore: file_names
import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController passwordController;
  const PasswordField(this.passwordController, {super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState(passwordController);
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  final TextEditingController passwordController;
  _PasswordFieldState(this.passwordController);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: passwordController,

      obscureText: _obscureText,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.cyanAccent,
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(
          color: Colors.white70,
          backgroundColor: Colors.transparent,
          fontFamily: 'PlusJakartaSans',
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 10, 100, 174),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 30, 30, 30),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}
