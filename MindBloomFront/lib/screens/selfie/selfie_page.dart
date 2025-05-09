import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/colors.dart';
import 'package:mindbloom/widgets/back_button.dart';

class SelfieUploadPage extends StatefulWidget {
  const SelfieUploadPage({super.key});

  @override
  State<SelfieUploadPage> createState() => _SelfieUploadPageState();
}

class _SelfieUploadPageState extends State<SelfieUploadPage> {
  File? _image;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Pick an image from the camera
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // Upload the selfie to Supabase and send to Flask for prediction
  Future<void> _uploadSelfie() async {
    if (_image == null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showErrorDialog('User not authenticated');
      return;
    }

    setState(() => _loading = true);

    try {
      // Envoyer directement l'image au serveur Flask pour analyse et stockage
      final response = await _sendSelfieToFlask(_image!);

      if (response != null) {
        final predictedClass = response['class'];
        final depressionScore = response['score'];
        final imageUrl = response['url']; // Récupérer l'URL fournie par Flask

        _showSuccessDialog(predictedClass, depressionScore);
      } else {
        _showErrorDialog('Prediction failed');
      }
    } catch (e) {
      _showErrorDialog('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Send the selfie image file to Flask for prediction
  Future<Map<String, dynamic>?> _sendSelfieToFlask(File imageFile) async {
    try {
      final session = _supabase.auth.currentSession;
      final accessToken = session?.accessToken;

      if (accessToken == null) {
        print('No access token found');
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.109:5000/predict'), // Flask API URL
      );

      // Attach image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Ajouter l'ID utilisateur dans le formulaire pour le serveur Flask
      request.fields['user_id'] = _supabase.auth.currentUser!.id;

      // Ajouter le token JWT à l'en-tête (pour référence future)
      request.headers['Authorization'] = 'Bearer $accessToken';

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var result = json.decode(responseData);
        return result; // returns the prediction result
      } else {
        print('Error from Flask API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error during API call: $e');
      return null;
    }
  }

  // Show error dialog
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

  // Show success dialog with predicted class and score
  void _showSuccessDialog(int predictedClass, double depressionScore) {
    String className = '';
    if (predictedClass == 0) {
      className = 'happy';
    } else if (predictedClass == 1) {
      className = 'sad';
    } else {
      className = 'neutral';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(
              'Your selfie has been uploaded successfully!\n\nPredicted Class: $className\nDepression Score: $depressionScore',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Selfie'),
        backgroundColor: AppColors.primary,
        leading: const BackButtonWidget(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Take Selfie'),
            ),
            const SizedBox(height: 20),
            if (_image != null)
              ElevatedButton(
                onPressed: _loading ? null : _uploadSelfie,
                child:
                    _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Analyze and Upload'),
              ),
          ],
        ),
      ),
    );
  }
}
