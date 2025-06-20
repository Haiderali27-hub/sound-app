import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/firebase_service.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _firebaseService = FirebaseService();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    setState(() {
      _nameError = Validators.validateName(_nameController.text);
      _emailError = Validators.validateEmail(_emailController.text);
      _passwordError = Validators.validatePassword(_passwordController.text);
    });

    if (_nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _agreeToTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
      // Call Firebase registration
        final user = await _firebaseService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

        if (user != null) {
          Get.snackbar(
            'Success',
            'Account created successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          // Navigate to login screen after successful registration
      Get.offAllNamed(AppRoutes.login);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_agreeToTerms) {
      Get.snackbar(
        'Error',
        'Please agree to the Terms and Conditions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a new\naccount',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2B55),
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  labelText: 'Full Name',
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  controller: _nameController,
                  validator: Validators.validateName,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Password',
                  isPassword: true,
                  errorText: _passwordError,
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'By creating an account, you agree to our ',
                          children: [
                            TextSpan(
                              text: 'Term and Conditions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Create account',
                  onPressed: _isLoading ? null : _validateAndSubmit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Get.offAllNamed(AppRoutes.login);
                          },
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: _isLoading ? Colors.grey : const Color(0xFF0D2B55),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
