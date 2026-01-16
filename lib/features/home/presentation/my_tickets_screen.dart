import 'package:flutter/material.dart';
import 'package:vibes/core/widgets/empty_state.dart';
import 'package:vibes/core/theme/app_theme.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes Tickets')),
      body: EmptyState(
        title: 'Aucun ticket acheté',
        subtitle: 'Réserve ta prochaine soirée pour voir tes billets ici.',
        icon: Icons.confirmation_num_outlined,
        actionLabel: 'Découvrir les événements',
        onAction: () => Navigator.of(context).pop(),
      ),
    );
  }
}
