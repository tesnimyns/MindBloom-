import 'package:flutter/material.dart';
import 'package:mindbloom/screens/home/home_page.dart';
import 'package:mindbloom/screens/selfie/selfie_page.dart';
import '../../screens/voice/voice_input_page.dart';
import 'package:mindbloom/screens/text_input/text_input_page.dart';

// Définition des routes
class AppRoutes {
  static const String home = '/home';
  static const String textInput = '/text_input';
  static const String voiceInput = '/voice_input';
  static const String selfie = '/selfie';

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => HomePage(),
      textInput: (context) => TextInputPage(),
      voiceInput: (context) => VoiceInputPage(),

      selfie: (context) => SelfieUploadPage(),

    };
  }
}
