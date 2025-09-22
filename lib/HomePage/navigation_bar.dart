import 'package:flutter/material.dart';
import 'package:v_comm/Calendar/calendar.dart';
import 'package:v_comm/Profile/profile.dart';

class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int selectedIndex = 0; // Home is selected by default

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CalendarPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // MODIFICATION: Matched margin, decoration, border, and shadow from calendar cards
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Exact card color from reference
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // MODIFICATION: Wrapped each icon in Expanded to prevent overflow
            _buildIcon(Icons.search, 0),
            _buildIcon(Icons.notifications, 1),
            _buildIcon(Icons.calendar_today, 2),
            _buildIcon(Icons.message, 3),
            _buildIcon(Icons.person, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    bool isSelected = selectedIndex == index;
    return Expanded(
      child: IconButton(
        icon: Icon(icon),
        iconSize: 26,
        color: Colors.white.withOpacity(
          0.5,
        ), // Subtle color change for selection
        onPressed: () => _onItemTapped(index),
      ),
    );
  }
}
