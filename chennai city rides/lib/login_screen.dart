import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

// Design System Tokens: "The Heritage Modernist"
class _Colors {
  static const primary = Color(0xFF004C22);
  static const primaryContainer = Color(0xFF166534);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF404940);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFA6F4B5);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static final Uri _googleRedirectUri = Uri(
    scheme: 'com.chennaicityrides.app',
    host: 'login-callback',
  );

  bool _isLoading = false;
  bool _isTermsAccepted = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String? get _redirectTo {
    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _googleRedirectUri.toString();
      default:
        return null;
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    if (!_isTermsAccepted) {
      _showSnackBar('Please accept Terms & Conditions to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final didLaunch = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectTo,
        scopes: 'email profile',
        queryParams: const {'prompt': 'select_account'},
      );

      if (!didLaunch && mounted) {
        _showSnackBar('Could not open Google sign in.');
      }
    } on AuthException catch (error) {
      if (mounted) _showSnackBar(error.message);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 48),
                  const Text(
                    'Welcome to\nChennai City\nRides',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: _Colors.onSurface,
                      letterSpacing: -1.5,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Premium transit for the city that never stops.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      color: _Colors.onSurfaceVariant.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildGoogleAuthCard(),
                  const SizedBox(height: 28),
                  _buildGoogleButton(),
                  const SizedBox(height: 48),
                  _buildTerms(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Colors.primaryContainer, _Colors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _Colors.primaryContainer.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: _Colors.onPrimary,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chennai City Rides',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _Colors.primaryContainer,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Premium Transit',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _Colors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleAuthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _Colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Colors.onSurface.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _Colors.primaryFixed.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Google Login',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _Colors.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Skip OTP and continue with your Google account.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _Colors.onSurface,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use any Gmail or Google Workspace account. Supabase keeps the session available for your next visit.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _buildBenefitRow(
            Icons.mark_email_read_outlined,
            'One tap with Google',
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(
            Icons.verified_user_outlined,
            'Secured by Supabase Auth',
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(
            Icons.phone_disabled_outlined,
            'No mobile OTP required',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _Colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: _Colors.primaryContainer),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _Colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signInWithGoogle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isTermsAccepted
              ? const LinearGradient(
                  colors: [_Colors.primaryContainer, _Colors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _isTermsAccepted ? null : _Colors.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: _isTermsAccepted 
              ? [
                  BoxShadow(
                    color: _Colors.primaryContainer.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              ),
            ] else ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _isTermsAccepted ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4285F4).withValues(alpha: _isTermsAccepted ? 1.0 : 0.6),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Text(
              _isLoading ? 'Opening Google...' : 'Continue with Google',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: _isTermsAccepted ? 1.0 : 0.7),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _isTermsAccepted,
                onChanged: (val) => setState(() => _isTermsAccepted = val ?? false),
                activeColor: _Colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(
                  color: _Colors.onSurfaceVariant.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: _Colors.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _Colors.primaryContainer,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsScreen()),
                          );
                        },
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _Colors.primaryContainer,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
