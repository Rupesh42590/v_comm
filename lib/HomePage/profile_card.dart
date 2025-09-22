import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileCard extends StatefulWidget {
  // Restored constructor to accept simple string values
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
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.isOn;
  }

  @override
  Widget build(BuildContext context) {
    // This is now a simple, non-tappable container
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // User Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name, // Displays the name from the constructor
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.dept, // Displays the department from the constructor
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customId, // Displays the ID from the constructor
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Switch Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoSwitch(
                value: _isOn,
                onChanged: (value) {
                  setState(() {
                    _isOn = value;
                  });
                },
                activeColor: Colors.grey.shade600,
                trackColor: Colors.black.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                _isOn ? "Online" : "Offline",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isOn
                      ? Colors.greenAccent.shade400
                      : Colors.redAccent.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
