import 'package:flutter/material.dart';
import 'package:v_comm/LoginPage/forgot_password.dart';
import 'package:v_comm/LoginPage/username.dart';
import 'package:v_comm/LoginPage/password.dart';
import 'package:v_comm/LoginPage/sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginContainerState();
}

class _LoginContainerState extends State<LoginPage> {
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 90),

          SizedBox(
            width: double.infinity,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'V-COMM',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 37),
            padding: const EdgeInsets.fromLTRB(23, 20, 23, 32),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 30, 30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Let\'s get started by filling out the form below.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    UserName(usernameController),
                    const SizedBox(height: 20),
                    PasswordField(passwordController),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [ForgotPassword(usernameController)],
                    ),
                    const SizedBox(height: 10),
                    SignInButton(usernameController, passwordController),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
