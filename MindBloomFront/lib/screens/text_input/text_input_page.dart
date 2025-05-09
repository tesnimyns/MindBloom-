import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindbloom/widgets/back_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../constants/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class TextInputPage extends StatefulWidget {
  const TextInputPage({super.key});

  @override
  State<TextInputPage> createState() => _TextInputPageState();
}

class _TextInputPageState extends State<TextInputPage> {
  final TextEditingController _textController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    if (_isLoading) return;

    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorDialog('Please write something before submitting.');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showErrorDialog('User not authenticated');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appel à l'API FastAPI (via ton URL FastAPI déployé)
      final response = await http.post(
        Uri.parse('https://77b0-197-20-157-10.ngrok-free.app/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': text, 'user_id': user.id}),
      );

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode}');
      }

      final analysis = json.decode(response.body);

      // Enregistrer l'analyse dans Supabase avec le score et le niveau
      await _supabase.from('thoughts').insert({
        'user_id': user.id,
        'content': text,
        'score': analysis['score_total'],
        'niveau': analysis['niveau'],
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showConfirmationDialog();
      _textController.clear();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to submit: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Submitted'),
            content: const Text(
              'Your thoughts have been submitted successfully.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/home');
                },
                child: const Text('View Score'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/selfie');
                },
                child: const Text('Take a Selfie'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/voice_input');
                },
                child: const Text('Record Voice'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Write Your Feelings'),
          elevation: 0,
          leading: const BackButtonWidget(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/images/thou.jpg', height: 180),
              const SizedBox(height: 24),
              Text(
                "How are you feeling today?",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomTextField(
                    controller: _textController,
                    hintText: 'Write your thoughts...',
                    obscureText: false,
                    maxLines: 8,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitText,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
