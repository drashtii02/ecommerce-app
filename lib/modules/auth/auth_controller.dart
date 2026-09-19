import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;

  // Real-time validation states
  final emailError = Rxn<String>();
  final passwordError = Rxn<String>();
  final emailTouched = false.obs;
  final passwordTouched = false.obs;

  // Password strength
  final passwordStrength = 0.0.obs; // 0.0 to 1.0

  // Animation
  late AnimationController animController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void onInit() {
    super.onInit();

    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    animController.forward();

    // Real-time validation listeners
    emailController.addListener(_validateEmailRealTime);
    passwordController.addListener(_validatePasswordRealTime);
  }

  void _validateEmailRealTime() {
    if (!emailTouched.value) return;
    emailError.value = validateEmail(emailController.text);
  }

  void _validatePasswordRealTime() {
    if (!passwordTouched.value) return;
    passwordError.value = validatePassword(passwordController.text);
    _updatePasswordStrength(passwordController.text);
  }

  void _updatePasswordStrength(String password) {
    if (password.isEmpty) {
      passwordStrength.value = 0.0;
      return;
    }
    double strength = 0.0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 10) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    passwordStrength.value = strength.clamp(0.0, 1.0);
  }

  Color getPasswordStrengthColor() {
    final s = passwordStrength.value;
    if (s <= 0.25) return Colors.red;
    if (s <= 0.5) return Colors.orange;
    if (s <= 0.75) return Colors.amber;
    return Colors.green;
  }

  String getPasswordStrengthLabel() {
    final s = passwordStrength.value;
    if (s <= 0.0) return '';
    if (s <= 0.25) return 'Weak';
    if (s <= 0.5) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong';
  }

  void onEmailFocusChanged(bool hasFocus) {
    if (!hasFocus && emailController.text.isNotEmpty) {
      emailTouched.value = true;
      emailError.value = validateEmail(emailController.text);
    }
  }

  void onPasswordFocusChanged(bool hasFocus) {
    if (!hasFocus && passwordController.text.isNotEmpty) {
      passwordTouched.value = true;
      passwordError.value = validatePassword(passwordController.text);
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> login() async {
    // Mark both fields as touched for validation display
    emailTouched.value = true;
    passwordTouched.value = true;
    emailError.value = validateEmail(emailController.text);
    passwordError.value = validatePassword(passwordController.text);

    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final success = await _authRepo.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (success) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        _showErrorSnackbar(
          'Login Failed',
          'Invalid credentials. Please try again.',
        );
      }
    } catch (e) {
      _showErrorSnackbar(
        'Error',
        'Something went wrong. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
      icon: Icon(Icons.error_outline, color: Colors.red.shade800),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
