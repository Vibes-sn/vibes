import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/home/presentation/home_screen.dart';

class VibesApp extends StatelessWidget {
  const VibesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibes',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
