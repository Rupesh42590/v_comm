import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide NavigationBar;
import 'package:flutter/services.dart';
import 'package:v_comm/HomePage/navigation_bar.dart';
import 'package:v_comm/Calendar/calendar.dart';
import 'package:v_comm/HomePage/profile_card.dart';

class Homepage extends StatefulWidget {
  User? user;
  Homepage({super.key, required this.user});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String name = "";
  String dept = "";
  String customId = "";
  bool isOn = true;
  @override
  void initState() {
    super.initState();
    fetchUserData(); // runs once when widget is created
  }

  Future<void> fetchUserData() async {
    if (widget.user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? "";
          dept = data?['dept'] ?? "";
          customId = data?['customId'] ?? "";
        });

        print("Name: $name, Dept: $dept, ID: $customId"); // print to console
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(
        children: [
          ProfileCard(name: name, dept: dept, customId: customId, isOn: isOn),
          Spacer(),
          NavigationBar(),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
