import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'screens/welcome/welcome_page.dart';
import 'routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MindBloomApp extends StatelessWidget {
  const MindBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindBloom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
      routes: AppRoutes.routes,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://xcieeonpxsirifymoohv.supabase.co', // Ton URL Supabase
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaWVlb25weHNpcmlmeW1vb2h2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2MTAwMTYsImV4cCI6MjA2MTE4NjAxNn0.rOd2dita7BEmVnU9NhaOd2T76IO4j4H_NRbffI8dwk4', // Ta clé anonyme
  );

  runApp(const MindBloomApp());
}
