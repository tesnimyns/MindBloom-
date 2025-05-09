import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validators.dart';
import '../home/home_page.dart';
import '../../widgets/back_button.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Client Supabase
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Sign Up'),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButtonWidget() : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                  controller: _firstNameController,
                  hintText: 'First Name',
                  obscureText: false,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _lastNameController,
                  hintText: 'Last Name',
                  obscureText: false,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  obscureText: false,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _ageController,
                  hintText: 'Age',
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Sign Up',
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final AuthResponse res = await supabase.auth.signUp(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );

                        if (res.user != null) {
                          // Insertion dans la table "profiles"
                          await supabase.from('profiles').insert({
                            'id': res.user!.id,
                            'first_name': _firstNameController.text.trim(),
                            'last_name': _lastNameController.text.trim(),
                            'age': int.parse(_ageController.text.trim()),
                          });

                          // Navigation vers la page d'accueil
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                          );
                        }
                      } on AuthException catch (e) {
                        String message = 'Registration failed';
                        if (e.message.contains('already registered')) {
                          message = 'Email already in use.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$message: ${e.message}')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
