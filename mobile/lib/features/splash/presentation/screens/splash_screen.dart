import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/data/models/branding_model.dart';
import '../../../settings/data/repositories/branding_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _fadeOut;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade out controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo scale animation with bounce effect
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_logoController);

    // Logo rotation animation
    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text opacity animation
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Text slide animation
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Fade out animation
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Pulse animation
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(_pulseController);
  }

  void _startAnimations() async {
    // Start logo animation
    _logoController.forward();

    // Start text animation after logo
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Start pulse animation
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseController.repeat();

    // Check auth state and navigate
    await Future.delayed(const Duration(milliseconds: 1500));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    // Fetch trainer branding for trainees (silent, non-blocking)
    if (user != null && user.isTrainee) {
      await _fetchTraineeBranding();
    } else {
      // Non-trainees and logged-out users should not have trainer branding
      await ref.read(themeProvider.notifier).clearTrainerBranding();
    }

    // Start fade out
    await _fadeController.forward();

    if (!mounted) return;

    if (user == null) {
      context.go('/login');
    } else if (user.isAdmin) {
      context.go('/admin');
    } else if (user.isTrainer) {
      context.go('/trainer');
    } else if (user.isTrainee && !user.onboardingCompleted) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  /// Fetch trainer branding for the current trainee and apply to theme.
  /// Fails silently — cached branding or defaults are used on error.
  Future<void> _fetchTraineeBranding() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final repository = BrandingRepository(apiClient);
      final result = await repository.getMyBranding();

      if (!mounted) return;

      if (result['success'] == true) {
        final branding = result['branding'] as BrandingModel;
        if (branding.isCustomized) {
          await ref.read(themeProvider.notifier).applyTrainerBranding(
            primaryColor: branding.primaryColorValue,
            secondaryColor: branding.secondaryColorValue,
            appName: branding.appName,
            logoUrl: branding.logoUrl,
          );
        } else {
          await ref.read(themeProvider.notifier).clearTrainerBranding();
        }
      }
      // On failure, cached branding from SharedPreferences persists
    } catch (_) {
      // Silent failure — branding is non-critical
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeOut,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Animated background circles
                  ..._buildBackgroundElements(theme),

                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo
                        AnimatedBuilder(
                          animation: Listenable.merge([_logoController, _pulseController]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value * _pulseAnimation.value,
                              child: Transform.rotate(
                                angle: _logoRotation.value,
                                child: _buildLogo(theme),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Animated text
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textOpacity,
                            child: _buildBrandedText(theme),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Loading indicator at bottom
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandedText(ThemeData theme) {
    final themeState = ref.read(themeProvider);
    final branding = themeState.trainerBranding;
    final appName = branding?.displayName ?? 'FitnessAI';
    final subtitle = branding != null && branding.isCustomized
        ? 'Powered by FitnessAI'
        : 'Your Personal Fitness Coach';

    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
          ).createShader(bounds),
          child: Text(
            appName,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodySmall?.color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(ThemeData theme) {
    final themeState = ref.read(themeProvider);
    final logoUrl = themeState.trainerBranding?.logoUrl;

    // If trainer has a custom logo, show it
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.network(
            logoUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultLogo(theme),
          ),
        ),
      );
    }

    return _buildDefaultLogo(theme);
  }

  Widget _buildDefaultLogo(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 50,
              color: Colors.white,
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Icon(
                Icons.auto_awesome,
                size: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundElements(ThemeData theme) {
    return [
      // Top right circle
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Transform.scale(
              scale: _logoScale.value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Bottom left circle
      Positioned(
        bottom: -150,
        left: -150,
        child: AnimatedBuilder(
          animation: _textController,
          builder: (context, child) {
            return Transform.scale(
              scale: _textOpacity.value,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
