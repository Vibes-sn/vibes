import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/home/presentation/home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _signInWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            null, // TODO: ajouter un redirect spécifique mobile/web si besoin
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Connexion Google indisponible pour le moment.'),
        ),
      );
    }
  }

  void _continueAsGuest(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1600',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.75)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  _Logo(),
                  const SizedBox(height: 16),
                  Text(
                    'Rejoins la nuit. Vis l\'instant.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _PrimaryButton(
                    text: 'Continuer avec Google',
                    onPressed: () => _signInWithGoogle(context),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    text: 'Se connecter avec son numéro',
                    onPressed: () =>
                        _showSnack(context, 'Connexion par numéro à venir.'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _continueAsGuest(context),
                    child: const Text(
                      'Continuer en tant qu\'invité',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/vibes-mascotte.png',
          height: 88,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ).createShader(rect),
            child: const Text(
              'Vibes',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
