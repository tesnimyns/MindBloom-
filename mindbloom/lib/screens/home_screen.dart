import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'journal_entry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("MindBloom"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Bienvenue sur ton espace mental 🌿",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
