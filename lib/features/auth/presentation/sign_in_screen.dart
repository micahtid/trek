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
          'Intern Growth Vault',
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

/// Custom Google "G" logo using colored arcs — no asset dependency.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

/// Paints a simplified Google "G" logo using Material colors.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue arc
    _drawArc(canvas, center, radius, -0.3, 1.6, const Color(0xFF4285F4));
    // Red arc
    _drawArc(canvas, center, radius, 1.3, 1.6, const Color(0xFFEA4335));
    // Yellow arc
    _drawArc(canvas, center, radius, 2.9, 1.0, const Color(0xFFFBBC05));
    // Green arc
    _drawArc(canvas, center, radius, 3.9, 0.9, const Color(0xFF34A853));

    // White circle in center (creates the "G" cut-out effect)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // "G" horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.height * 0.18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.85, center.dy),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double start,
      double sweep, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
