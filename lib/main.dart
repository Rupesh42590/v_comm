import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';
import 'package:v_comm/LoginPage/login_page.dart';
import 'package:v_comm/HomePage/homepage.dart';
import 'package:v_comm/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blueAccent, // 1. The blinking cursor line
          // MODIFICATION: THIS IS THE LINE THAT CHANGES THE HIGHLIGHT
          selectionColor: Colors.blueAccent.withOpacity(
            0.4,
          ), // 2. The highlight background

          selectionHandleColor: Colors.blueAccent, // 3. The teardrop handles
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: const AuthGate(),
      ),
    );
  }
}
