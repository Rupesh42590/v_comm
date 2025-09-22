import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController passwordController;
  const PasswordField(this.passwordController, {super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isPasswordObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.passwordController,
      cursorColor: Colors.blue,
      obscureText: _isPasswordObscured,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withOpacity(0.6),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
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
