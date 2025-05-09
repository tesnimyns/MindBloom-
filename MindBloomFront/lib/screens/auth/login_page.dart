import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindbloom/widgets/back_button.dart';
import '../../constants/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validators.dart';
import '../home/home_page.dart';
import 'signup_page.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (response.user == null) throw Exception('Login failed');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on AuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Email or password is incorrect';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Login'),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButtonWidget() : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _login(),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgetPasswordPage(),
                          ),
                        ),
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        ),
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
