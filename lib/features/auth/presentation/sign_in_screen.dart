import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_state.dart';
import 'auth_provider.dart';

/// Sign-in screen — minimal + bold. Logo, tagline, single Google button.
///
/// Per user decision: no onboarding, no value pitch. Confident and clean.
/// Layout: vertically centered toward upper third, white/light background,
/// amber accent on the button.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading ||
        authAsync.asData?.value is AuthStateLoading;

    // Show error from auth state if any
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Sign in failed: ${next.error}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildLogoArea(context),
                const SizedBox(height: 48),
                _buildTagline(context),
                const SizedBox(height: 56),
                _buildSignInButton(context, ref, isLoading),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoArea(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Logo placeholder — amber vault icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.lock_outlined,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        // App name
        Text(
          'Intern Vault',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Text(
      'Every day builds your future.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.grey.shade600,
        height: 1.5,
      ),
    );
  }

  Widget _buildSignInButton(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return Column(
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Signing in...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          ref.read(authNotifierProvider.notifier).signIn();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          foregroundColor: colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            const SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google "G" logo rendered as a proper SVG-like path.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48; // scale factor (paths designed for 48x48)

    // Blue (right side + horizontal bar)
    final blue = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(43.611 * s, 20.083 * s)
      ..lineTo(43.611 * s, 23.917 * s)
      ..lineTo(25 * s, 23.917 * s)
      ..lineTo(25 * s, 20.083 * s)
      ..close()
      ..moveTo(43.611 * s, 20.083 * s)
      ..cubicTo(43.611 * s, 18.812 * s, 43.5 * s, 17.583 * s, 43.298 * s, 16.417 * s)
      ..lineTo(25 * s, 16.417 * s)
      ..lineTo(25 * s, 23.917 * s)
      ..lineTo(35.517 * s, 23.917 * s)
      ..cubicTo(34.933 * s, 26.833 * s, 33.244 * s, 29.317 * s, 30.789 * s, 31.017 * s)
      ..lineTo(30.789 * s, 31.017 * s)
      ..lineTo(36.294 * s, 35.317 * s)
      ..cubicTo(40.094 * s, 31.817 * s, 43.611 * s, 26.417 * s, 43.611 * s, 20.083 * s)
      ..close();
    canvas.drawPath(bluePath, blue);

    // Green (bottom-right)
    final green = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(25 * s, 38.583 * s)
      ..cubicTo(20.178 * s, 38.583 * s, 16.006 * s, 36.117 * s, 13.289 * s, 32.417 * s)
      ..lineTo(7.783 * s, 36.717 * s)
      ..cubicTo(11.733 * s, 42.817 * s, 17.883 * s, 46.917 * s, 25 * s, 46.917 * s)
      ..cubicTo(30.6 * s, 46.917 * s, 35.5 * s, 45.017 * s, 39.294 * s, 41.317 * s)
      ..lineTo(33.789 * s, 37.017 * s)
      ..cubicTo(31.583 * s, 38.083 * s, 28.917 * s, 38.583 * s, 25 * s, 38.583 * s)
      ..close();
    // Simplified — just use a sector approach
    canvas.drawPath(greenPath, green);

    // Yellow (bottom-left)
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.417 * s, 24 * s)
      ..cubicTo(10.417 * s, 22.483 * s, 10.717 * s, 21.017 * s, 11.217 * s, 19.667 * s)
      ..lineTo(5.711 * s, 15.367 * s)
      ..cubicTo(4.306 * s, 18.017 * s, 3.5 * s, 20.917 * s, 3.5 * s, 24 * s)
      ..cubicTo(3.5 * s, 27.083 * s, 4.306 * s, 29.983 * s, 5.711 * s, 32.633 * s)
      ..lineTo(11.217 * s, 28.333 * s)
      ..cubicTo(10.717 * s, 26.983 * s, 10.417 * s, 25.517 * s, 10.417 * s, 24 * s)
      ..close();
    canvas.drawPath(yellowPath, yellow);

    // Red (top-left)
    final red = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(25 * s, 9.417 * s)
      ..cubicTo(28.239 * s, 9.417 * s, 31.117 * s, 10.517 * s, 33.389 * s, 12.583 * s)
      ..lineTo(38.889 * s, 7.083 * s)
      ..cubicTo(35.167 * s, 3.633 * s, 30.333 * s, 1.083 * s, 25 * s, 1.083 * s)
      ..cubicTo(17.883 * s, 1.083 * s, 11.733 * s, 5.183 * s, 7.783 * s, 11.283 * s)
      ..lineTo(13.289 * s, 15.583 * s)
      ..cubicTo(16.006 * s, 11.883 * s, 20.178 * s, 9.417 * s, 25 * s, 9.417 * s)
      ..close();
    canvas.drawPath(redPath, red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
