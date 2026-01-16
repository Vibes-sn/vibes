import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/services/auth_service.dart';
import 'package:vibes/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _isSignUp = false;

  void _showFeedback({required String message, bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [Colors.red.shade900, Colors.red.shade700]
                  : const [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.red : AppColors.gradientStart)
                    .withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    final pwd = _passwordController.text;
    final name = _nameController.text.trim();
    if (email.isEmpty || pwd.isEmpty || (_isSignUp && name.isEmpty)) {
      _showFeedback(message: 'Complète les champs requis.', isError: true);
      return;
    }
    if (pwd.length < 6) {
      _showFeedback(
        message: 'Mot de passe trop court (min 6 caractères).',
        isError: true,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      if (_isSignUp) {
        await _auth.signUp(email: email, password: pwd, fullName: name);
        if (client.auth.currentSession == null) {
          // Flow MVP : on enchaîne un sign-in pour connecter immédiatement
          await _auth.signIn(email: email, password: pwd);
        }
      } else {
        await _auth.signIn(email: email, password: pwd);
      }
      if (!mounted) return;
      _showFeedback(
        message: _isSignUp
            ? 'Compte créé, bienvenue sur Vibes !'
            : 'Connexion réussie.',
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          Container(color: const Color(0xFF0A0E1A).withValues(alpha: 0.8)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/vibes-logo-magenta-ori.png',
                        height: 48,
                        fit: BoxFit.contain,
                        semanticLabel: 'Vibes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _isSignUp ? 'Inscris-toi' : 'Connecte-toi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Crée ton compte en quelques secondes.'
                        : 'Rentre tes identifiants pour accéder à Vibes.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isSignUp) ...[
                    _Field(label: 'Nom complet', controller: _nameController),
                    const SizedBox(height: 14),
                  ],
                  _Field(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'Mot de passe',
                    controller: _passwordController,
                    obscure: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppColors.gradientStart,
                        foregroundColor: Colors.white,
                        shadowColor: AppColors.gradientStart.withValues(
                          alpha: 0.5,
                        ),
                        elevation: 12,
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Créer mon compte' : 'Se connecter',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Déjà un compte ? Connecte-toi'
                            : 'Pas encore de compte ? Inscris-toi',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1470229538611-16ba8c7ffbd7?w=1600',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.2),
            BlendMode.darken,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Nunito',
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gradientStart),
        ),
      ),
    );
  }
}
