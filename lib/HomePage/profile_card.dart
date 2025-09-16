import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProfileCard extends StatefulWidget {
  final String name;
  final String dept;
  final String customId;
  final bool isOn;

  const ProfileCard({
    required this.name,
    required this.dept,
    required this.customId,
    required this.isOn,
    super.key,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late bool _isOn; // local mutable copy

  @override
  void initState() {
    super.initState();
    _isOn = widget.isOn; // initialize local state
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      constraints: const BoxConstraints(maxWidth: 350, minWidth: 250),
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
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.dept,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            widget.customId,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          CupertinoSwitch(
            value: _isOn,
            onChanged: (value) {
              setState(() {
                _isOn = value;
              });
            },
            activeColor: Colors.blue,
            trackColor: Colors.grey.shade800,
          ),
        ],
      ),
    );
  }
}
