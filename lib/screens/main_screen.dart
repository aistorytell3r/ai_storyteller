// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'parent_input_screen.dart';
import 'child_input_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.auto_stories, color: Colors.white), // Change book icon color to white
            SizedBox(width: 8),
            Text(
              'AI StoryTeller',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white, // Set text color to white
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white), // Set icon color to white
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentInputScreen(),
                ),
              );
            },
            tooltip: 'おとなむけ',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white), // Set icon color to white
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: '設定',
          ),
        ],
        backgroundColor: Colors.purple.shade100, // Set AppBar background color to light purple
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: const ChildInputScreen(),
      ),
    );
  }
}