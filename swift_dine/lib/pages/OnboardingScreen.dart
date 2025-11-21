import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/services.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:swift_dine/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  double _animationValue = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  bool _isControllerInitialized = false;
  bool _showGlassCard = false;

  // Swipe variables for INITIAL CARD
  double _swipeProgress = 0;
  double _maxSwipeWidth = 0;
  bool _swipeCompleted = false;
  late AnimationController _swipeController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _blurAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isControllerInitialized = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_controller.isDismissed) {
          _controller.forward();
        }
        setState(() => _animationValue = 1);
      });
    });
  }

  void _revealGlassCard() {
    if (_swipeCompleted) return;
    _swipeCompleted = true;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _showGlassCard = true;
    });
    _controller.reset();
    _controller.forward();
  }

  // Swipe methods for INITIAL CARD
  void _onSwipeUpdate(DragUpdateDetails details) {
    if (_swipeCompleted || _showGlassCard) return;

    setState(() {
      _swipeProgress += details.delta.dx;
      if (_swipeProgress < 0) _swipeProgress = 0;
      if (_swipeProgress > _maxSwipeWidth - 60) {
        _swipeProgress = _maxSwipeWidth - 60;
        _revealGlassCard();
      }
    });
  }

  void _onSwipeEnd(DragEndDetails details) {
    if (_swipeCompleted || _showGlassCard) return;

    if (_swipeProgress > _maxSwipeWidth * 0.7) {
      _revealGlassCard();
    } else {
      setState(() {
        _swipeProgress = 0;
      });
    }
  }

  // Tap to animate swipe automatically
  void _onSwipeAreaTap() {
    if (_swipeCompleted || _showGlassCard) return;

    // Animate the swipe button to the end
    final animation = Tween<double>(
      begin: _swipeProgress,
      end: _maxSwipeWidth - 60,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));

    _swipeController.addListener(() {
      setState(() {
        _swipeProgress = animation.value;
      });
    });

    _swipeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _revealGlassCard();
      }
    });

    _swipeController.forward(from: 0);
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    _maxSwipeWidth = size.width * 0.7;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          /// 🌄 Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://images.pexels.com/photos/1510690/pexels-photo-1510690.jpeg?auto=compress&cs=tinysrgb&w=1080',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.coffee, color: theme.colorScheme.primary, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      'MezaHub',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 🎨 Dynamic Gradient Overlay
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _showGlassCard
                    ? [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.8),
                ]
                    : [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
                stops: _showGlassCard ? [0.0, 0.5, 1.0] : const [0.0, 0.3, 0.6, 0.8, 1.0],
              ),
            ),
          ),

          /// ✨ Initial Content with SWIPE
          if (!_showGlassCard) ...[
            // Floating Icons
            Positioned(
              top: 100,
              right: 30,
              child: AnimatedContainer(
                duration: const Duration(seconds: 4),
                curve: Curves.easeInOut,
                child: Icon(Iconsax.coffee, color: Colors.white.withOpacity(0.3), size: 24),
              ),
            ),
            Positioned(
              top: 180,
              left: 40,
              child: AnimatedContainer(
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOut,
                child: Icon(Iconsax.cake, color: Colors.white.withOpacity(0.2), size: 20),
              ),
            ),

            // Branding Badge
            Positioned(
              top: 60,
              left: 24,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                transform: Matrix4.translationValues(0, (1 - _animationValue) * 50, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    'S',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // 🎯 INITIAL CARD WITH SWIPE INTERACTION
            _isControllerInitialized
                ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _fadeAnimation.value) * 50),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome to',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.black.withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ShaderMask(
                                      shaderCallback: (bounds) => AppColors.primaryGradient(context).createShader(bounds),
                                      child: Text(
                                        'MezaHub',
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ready to discover amazing food experiences?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.black.withOpacity(0.8),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // 🎯 SWIPE INTERACTION ON INITIAL CARD (Now tappable too)
                                    Container(
                                      width: double.infinity,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(35),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Progress fill
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 100),
                                            width: _swipeProgress + 60,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient(context),
                                              borderRadius: BorderRadius.circular(35),
                                            ),
                                          ),

                                          // Swipe text
                                          if (_swipeProgress < 10)
                                            Center(
                                              child: Text(
                                                'Swipe or Tap to continue →',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),

                                          // Tappable background area
                                          Positioned.fill(
                                            child: GestureDetector(
                                              onTap: _onSwipeAreaTap,
                                              behavior: HitTestBehavior.opaque,
                                            ),
                                          ),

                                          // Draggable handle (now interactive)
                                          Positioned(
                                            left: _swipeProgress,
                                            child: GestureDetector(
                                              onHorizontalDragUpdate: _onSwipeUpdate,
                                              onHorizontalDragEnd: _onSwipeEnd,
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                margin: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(2, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Iconsax.arrow_right_3,
                                                  color: theme.colorScheme.primary,
                                                  size: 24,
                                                ),
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
                  ),
                );
              },
            )
                : const SizedBox(),
          ],

          /// 🧊 GLASS MORPHISM CARD (Appears after swipe/tap)
          if (_showGlassCard) ...[
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurAnimation.value * 15,
                sigmaY: _blurAnimation.value * 15,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),

            _isControllerInitialized
                ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _fadeAnimation.value) * 30),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                    spreadRadius: -10,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.15),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (bounds) => AppColors.primaryGradient(context).createShader(bounds),
                                          child: Text(
                                            'MezaHub',
                                            style: GoogleFonts.poppins(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              height: 1,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Ready to ',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 1.2,
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Feast',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.colorScheme.primary,
                                                  height: 1.2,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '?',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Join thousands of food lovers discovering amazing restaurants near you.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white.withOpacity(0.9),
                                            height: 1.6,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 36),

                                        // ✅ CONTINUE TO APP BUTTON
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withOpacity(0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 60,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: theme.colorScheme.primary,
                                                foregroundColor: theme.colorScheme.onPrimary,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              onPressed: _navigateToHome,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Continue to App',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Icon(
                                                    Iconsax.arrow_right_3,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // ✅ ALREADY HAVE ACCOUNT CONTAINER
                                        Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              color: Colors.white.withOpacity(0.1),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: TextButton(
                                              onPressed: _navigateToLogin,
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Already have an account? ',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        color: Colors.white.withOpacity(0.8),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: 'Sign In',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
            )
                : const SizedBox(),
          ],
        ],
      ),
    );
  }
}