import 'package:flutter/material.dart';
import 'package:v_comm/Calendar/calendar.dart';

class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIcon(Icons.search, 0),
              _buildIcon(Icons.notifications, 1),
              _buildIcon(Icons.calendar_today, 2),
              _buildIcon(Icons.message, 3),
              _buildIcon(Icons.person, 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.white,
      onPressed: () {
        setState(() {
          selectedIndex = index;
        });

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CalendarPage()),
          );
        }
      },
    );
  }
}
