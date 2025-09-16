import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide NavigationBar;
import 'package:flutter/services.dart';
import 'package:v_comm/HomePage/navigation_bar.dart';
import 'package:flutter/cupertino.dart';

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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // height adapts to content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "$name",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "$dept",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 5),
                Text(
                  "$customId",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 20),
                CupertinoSwitch(
                  value: isOn,
                  onChanged: (value) {
                    setState(() {
                      isOn = value;
                    });
                  },
                  activeColor: Colors.blue,
                  trackColor: Colors.grey.shade800,
                ),
              ],
            ),
          ),
          Spacer(),
          NavigationBar(),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
