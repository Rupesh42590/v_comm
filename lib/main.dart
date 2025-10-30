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
      theme: ThemeData(
        // MODIFICATION: Changed ThemeData() to ThemeData.dark()
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        // This is the key part: customize the color scheme
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          // Set the glow color here. Using transparent removes it.
          // You could also use something like Colors.grey.
          secondary: Colors.transparent,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blueAccent,
          selectionColor: Colors.blueAccent.withOpacity(0.4),
          selectionHandleColor: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      home: const AuthGate(), // MODIFICATION: Removed the extra Scaffold
    );
  }
}
