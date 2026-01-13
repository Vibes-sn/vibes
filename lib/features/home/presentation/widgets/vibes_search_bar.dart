import 'package:flutter/material.dart';
import 'package:vibes/core/theme/app_theme.dart';

class VibesSearchBar extends StatelessWidget {
  const VibesSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Chercher une soirée...',
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      ),
    );
  }
}
