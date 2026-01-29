import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/api_config_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricName = 'Face ID';
  bool _isAuthenticating = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBiometricStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricLoginEnabled();
    final name = await _biometricService.getBiometricName();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricName = name;
      });

      if (available && enabled) {
        _handleBiometricLogin();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    final authState = ref.read(authStateProvider);

    if (authState.user != null) {
      if (_rememberMe && _biometricAvailable) {
        await _biometricService.enableBiometricLogin(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        final user = authState.user!;
        if (user.isAdmin) {
          context.go('/admin');
        } else if (user.isTrainer) {
          context.go('/trainer');
        } else if (user.isTrainee && !user.onboardingCompleted) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      }
    } else if (authState.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to sign in',
      );

      if (authenticated) {
        final credentials = await _biometricService.getStoredCredentials();
        if (credentials != null) {
          await ref.read(authStateProvider.notifier).login(
                credentials['email']!,
                credentials['password']!,
              );

          final authState = ref.read(authStateProvider);

          if (authState.user != null && mounted) {
            final user = authState.user!;
            if (user.isAdmin) {
              context.go('/admin');
            } else if (user.isTrainer) {
              context.go('/trainer');
            } else if (user.isTrainee && !user.onboardingCompleted) {
              context.go('/onboarding');
            } else {
              context.go('/home');
            }
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    // TODO: Implement Google Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In coming soon!')),
    );
  }

  Future<void> _handleAppleLogin() async {
    // TODO: Implement Apple Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In coming soon!')),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(
      text: ApiConfigService.getBaseUrlSync(),
    );

    showDialog(
      context: context,
      builder: (context) {
        final dialogTheme = Theme.of(context);
        return AlertDialog(
          backgroundColor: dialogTheme.cardColor,
          title: const Text('Server Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your backend server URL:',
                style: TextStyle(
                    color: dialogTheme.textTheme.bodySmall?.color,
                    fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: TextStyle(color: dialogTheme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'https://your-ngrok-url.ngrok.io',
                  filled: true,
                  fillColor: dialogTheme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Default: ${ApiConfigService.defaultBaseUrl}',
                style: TextStyle(
                    color: dialogTheme.textTheme.bodySmall?.color,
                    fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ApiConfigService.resetToDefault();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset to default URL')),
                  );
                }
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  await ApiConfigService.setBaseUrl(url);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Server URL updated to: $url')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogTheme.colorScheme.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Colors matching the reference design
    final inputFillColor = theme.brightness == Brightness.light
        ? const Color(0xFFF5F5F8)
        : theme.cardColor;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.1),

                      // Logo and Brand
                      _buildLogo(theme, accentColor),

                      SizedBox(height: size.height * 0.06),

                      // Login Form
                      _buildLoginForm(inputFillColor, accentColor),

                      const SizedBox(height: 16),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot your password?',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      _buildLoginButton(authState, accentColor),

                      // Biometric login
                      if (_biometricAvailable && _biometricEnabled) ...[
                        const SizedBox(height: 16),
                        _buildBiometricButton(theme, accentColor),
                      ],

                      const SizedBox(height: 32),

                      // Divider
                      _buildDivider(theme),

                      const SizedBox(height: 32),

                      // Social Login Buttons
                      _buildSocialButtons(theme),

                      // Extra space for the fixed bottom trainer link
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Trainer Link - Fixed at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildTrainerLink(theme),
          ),

          // Server config button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              onPressed: _showServerConfigDialog,
              tooltip: 'Server Settings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeData theme, Color accentColor) {
    return Column(
      children: [
        // Logo Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stylized icon like the reference
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.8),
                  accentColor,
                ],
              ).createShader(bounds),
              child: const Icon(
                Icons.bolt,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // Brand name with letter spacing
            Text(
              'fitnessai',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                letterSpacing: 6,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm(Color inputFillColor, Color accentColor) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'email',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'password',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthState authState, Color accentColor) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: authState.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: authState.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'Log In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricButton(ThemeData theme, Color accentColor) {
    return Center(
      child: TextButton.icon(
        onPressed: _isAuthenticating ? null : _handleBiometricLogin,
        icon: _isAuthenticating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
            : Icon(
                _biometricName == 'Face ID' ? Icons.face : Icons.fingerprint,
                color: accentColor,
              ),
        label: Text(
          'Use $_biometricName',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or Log in with',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Button
        _buildSocialButton(
          onTap: _handleGoogleLogin,
          icon: const FaIcon(
            FontAwesomeIcons.google,
            size: 24,
            color: Colors.red,
          ),
          theme: theme,
        ),

        const SizedBox(width: 24),

        // Apple Button
        _buildSocialButton(
          onTap: _handleAppleLogin,
          icon: Icon(
            Icons.apple,
            size: 28,
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
          ),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? Colors.white
              : theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildTrainerLink(ThemeData theme) {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/register'),
        child: Text(
          'Are you a trainer?',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
