import 'package:flutter/material.dart';

class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Floating Navigation Bar
          Positioned(
            bottom: 5,
            left: 40,
            right: 40,

            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: selectedIndex == 0 ? Colors.blue : Colors.white,
                    onPressed: () => setState(() => selectedIndex = 0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    color: selectedIndex == 1 ? Colors.blue : Colors.white,
                    onPressed: () => setState(() => selectedIndex = 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message),
                    color: selectedIndex == 2 ? Colors.blue : Colors.white,
                    onPressed: () => setState(() => selectedIndex = 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    color: selectedIndex == 3 ? Colors.blue : Colors.white,
                    onPressed: () => setState(() => selectedIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
