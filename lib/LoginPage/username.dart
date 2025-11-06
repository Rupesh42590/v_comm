import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserName extends StatelessWidget {
  final TextEditingController usernameController;

  const UserName(this.usernameController, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: usernameController,
      cursorColor: Colors.blue,

      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: "Username (Email)",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(
          Icons.person_outline,
          color: Colors.white.withOpacity(0.6),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
