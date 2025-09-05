import 'package:flutter/material.dart';

class UserName extends StatelessWidget {
  const UserName({super.key});

  @override
  Widget build(context) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.cyanAccent,
      decoration: InputDecoration(
        labelText: "Username",
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
      ),
    );
  }
}
