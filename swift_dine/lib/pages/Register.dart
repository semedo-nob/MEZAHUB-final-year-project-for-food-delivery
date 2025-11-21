import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:swift_dine/services/auth_service.dart';
import '../provider/user_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isControllerInitialized = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isControllerInitialized = true;
      });
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
        );

        if (user != null) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.loadUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created successfully!'),
              backgroundColor: AppColors.primaryLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F1210), const Color(0xFF1A1D1B)]
                : [const Color(0xFFFAFDF9), const Color(0xFFF8FBF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const NetworkImage(
                    'https://www.transparenttextures.com/patterns/subtle-white-feathers.png',
                  ),
                  fit: BoxFit.cover,
                  opacity: isDark ? 0.05 : 0.1,
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 60,
              left: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.primaryLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : AppColors.primaryLight),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            if (_isControllerInitialized)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _fadeAnimation.value) * 30),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: screenHeight * 0.03,
                            ),
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxWidth: 400,
                                minWidth: screenWidth > 400 ? 400 : screenWidth * 0.9,
                              ),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A1D1B).withOpacity(0.9)
                                    : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : AppColors.primaryLight.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Logo/Title - Centered
                                    Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            "MezaHub",
                                            style: GoogleFonts.poppins(
                                              color: isDark ? Colors.white : AppColors.primaryLight,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Food for Everyone",
                                            style: GoogleFonts.poppins(
                                              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Sign Up Header
                                    Text(
                                      "Create Account",
                                      style: GoogleFonts.poppins(
                                        color: isDark ? Colors.white : AppColors.textColorLight,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Join MezaHub today and discover amazing food from local vendors in your community.",
                                      style: GoogleFonts.poppins(
                                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Full Name field
                                    _buildInputField(
                                      context: context,
                                      controller: _nameController,
                                      label: 'Full Name',
                                      prefixIcon: Iconsax.user,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your full name';
                                        }
                                        if (value.length < 2) {
                                          return 'Name must be at least 2 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Email field
                                    _buildInputField(
                                      context: context,
                                      controller: _emailController,
                                      label: 'Email Address',
                                      prefixIcon: Iconsax.sms,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@') || !value.contains('.')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Password field
                                    _buildInputField(
                                      context: context,
                                      controller: _passwordController,
                                      label: 'Password',
                                      prefixIcon: Iconsax.lock,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                                          color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Confirm Password field
                                    _buildInputField(
                                      context: context,
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      prefixIcon: Iconsax.lock_1,
                                      obscureText: _obscureConfirm,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                                          color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Remember me
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) => setState(() => _rememberMe = value!),
                                            fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                              if (states.contains(MaterialState.selected)) {
                                                return AppColors.primaryLight;
                                              }
                                              return Colors.transparent;
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Remember me",
                                          style: GoogleFonts.poppins(
                                            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Sign up button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryLight,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: _isLoading ? null : _submitForm,
                                        child: _isLoading
                                            ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                            : Text(
                                          "Create MezaHub Account",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: isDark ? Colors.white30 : Colors.grey.shade300,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            "Or continue with",
                                            style: GoogleFonts.poppins(
                                              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: isDark ? Colors.white30 : Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Social login buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isDark ? Colors.white : Colors.black,
                                              side: BorderSide(
                                                color: isDark ? Colors.white30 : Colors.grey.shade300,
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {},
                                            icon: const Icon(Iconsax.gallery, size: 20),
                                            label: Text(
                                              "Google",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isDark ? Colors.white : Colors.black,
                                              side: BorderSide(
                                                color: isDark ? Colors.white30 : Colors.grey.shade300,
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {},
                                            icon: const Icon(Iconsax.apple, size: 20),
                                            label: Text(
                                              "Apple",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Login link
                                    Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Already have an account? ",
                                            style: GoogleFonts.poppins(
                                              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                                              fontSize: 14,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _isLoading
                                                ? null
                                                : () {
                                              Navigator.pushReplacementNamed(context, '/login');
                                            },
                                            child: Text(
                                              "Sign in",
                                              style: GoogleFonts.poppins(
                                                color: AppColors.primaryLight,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : AppColors.textColorLight,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
            fontSize: 14,
          ),
          prefixIcon: Icon(prefixIcon,
              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
              size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: GoogleFonts.poppins(
            color: Colors.amber.shade200,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}