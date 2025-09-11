import 'package:flutter/material.dart' hide NavigationBar;
import 'package:v_comm/HomePage/navigation_bar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: const NavigationBar()));
  }
}
