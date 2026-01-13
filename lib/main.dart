import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/app.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ioilbrbfvgqceasraodu.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvaWxicmJmdmdxY2Vhc3Jhb2R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzMTgxOTQsImV4cCI6MjA4Mzg5NDE5NH0.x5Wwq__DXk47jtUDYppFHR47mLmrttcJSmK0uqn-Pvg',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';
  await initializeDateFormatting('fr_FR');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    DevicePreview(
      enabled: true, // désactivable en prod
      builder: (context) => const VibesApp(),
    ),
  );
}
