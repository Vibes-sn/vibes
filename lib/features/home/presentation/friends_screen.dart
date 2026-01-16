import 'package:flutter/material.dart';
import 'package:vibes/core/widgets/empty_state.dart';
import 'package:vibes/core/theme/app_theme.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes Amis')),
      body: EmptyState(
        title: 'Aucun ami pour le moment',
        subtitle: 'Invite tes proches et découvre leurs sorties.',
        icon: Icons.group_outlined,
        actionLabel: 'Inviter des amis',
        onAction: () => Navigator.of(context).pop(),
      ),
    );
  }
}
