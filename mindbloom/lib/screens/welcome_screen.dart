import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import '../theme/colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Image.asset('assets/images/welcome.jpg', height: 250),
            const SizedBox(height: 30),
            const Text(
              "Bienvenue sur MindBloom 🌸",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 175, 83, 134),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Commence ton voyage vers un esprit plus serein. Note tes pensées, écoute-toi, et laisse MindBloom t’accompagner.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.text),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 212, 100, 203),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
              child: const Text(
                "Commencer",
                style: TextStyle(fontSize: 18, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
