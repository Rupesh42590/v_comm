import 'package:flutter/material.dart';
import 'package:v_comm/LoginPage/forgot_password.dart';
import 'package:v_comm/LoginPage/username.dart';
import 'package:v_comm/LoginPage/password.dart';
import 'package:v_comm/LoginPage/sign_in.dart';
import 'package:v_comm/LoginPage/sign_up.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';

class LoginContainer extends StatefulWidget {
  const LoginContainer({super.key});

  @override
  State<LoginContainer> createState() => _LoginContainerState();
}

class _LoginContainerState extends State<LoginContainer> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserName(usernameController),
        const SizedBox(height: 20),
        PasswordField(passwordController),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [ForgotPassword()],
        ),
        const SizedBox(height: 10),
        SignInButton(usernameController, passwordController),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Don\'t have an account yet? ',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SignUpButton(usernameController, passwordController),
          ],
        ),
      ],
    );
  }
}
