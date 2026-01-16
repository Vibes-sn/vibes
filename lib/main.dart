import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/state/user_provider.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/auth/presentation/login_screen.dart';
import 'package:vibes/features/home/presentation/home_screen.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ioilbrbfvgqceasraodu.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvaWxicmJmdmdxY2Vhc3Jhb2R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzMTgxOTQsImV4cCI6MjA4Mzg5NDE5NH0.x5Wwq__DXk47jtUDYppFHR47mLmrttcJSmK0uqn-Pvg',
);

const bool _useDevicePreview = !kReleaseMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';
  await initializeDateFormatting('fr_FR');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    _useDevicePreview
        ? DevicePreview(
            enabled: true,
            builder: (context) =>
                UserScope(notifier: UserProvider(), child: const _RootApp()),
          )
        : UserScope(notifier: UserProvider(), child: const _RootApp()),
  );
}

class _RootApp extends StatelessWidget {
  const _RootApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibes',
      debugShowCheckedModeBanner: false,
      locale: _useDevicePreview ? DevicePreview.locale(context) : null,
      builder: _useDevicePreview ? DevicePreview.appBuilder : null,
      theme: AppTheme.dark,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          final data = snapshot.data;
          final session = data?.session;
          if (session != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.05).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFFFF6FB1), Color(0xFFFF9F66)],
            ).createShader(rect),
            child: const Text(
              'Vibes',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
