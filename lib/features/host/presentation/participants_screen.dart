import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibes/core/theme/app_theme.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  late final SupabaseClient _client;
  late final User _user;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté.');
    }
    _user = user;
  }

  Future<List<Map<String, dynamic>>> _loadParticipants() async {
    final rows = await _client
        .from('tickets')
        .select(
          'status, purchase_date, profiles(full_name, phone_number), events!inner(title, price, host_id)',
        )
        .eq('events.host_id', _user.id)
        .order('purchase_date', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  String? _normalizePhone(String? raw) {
    if (raw == null) return null;
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 9) {
      digits = '221$digits';
    }
    return digits;
  }

  Future<void> _openWhatsApp(String? rawPhone) async {
    final phone = _normalizePhone(rawPhone);
    if (phone == null) {
      _showFeedback('Numéro invalide', isError: true);
      return;
    }
    final uri = Uri.parse('https://wa.me/$phone');
    if (!await canLaunchUrl(uri)) {
      _showFeedback('WhatsApp indisponible', isError: true);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFeedback(String message, {bool isError = false}) {
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
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  bool _isVvip(num price) => price >= 150000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Liste des participants')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadParticipants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gradientStart),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erreur de chargement des participants.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(
              child: Text(
                'Aucun participant.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = rows[index];
              final profile = row['profiles'] as Map<String, dynamic>?;
              final event = row['events'] as Map<String, dynamic>?;
              final name = profile?['full_name'] as String? ?? 'Participant';
              final phone = profile?['phone_number'] as String?;
              final title = event?['title'] as String? ?? 'Événement';
              final price = (event?['price'] ?? 0) as num;
              final isVvip = _isVvip(price);
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white10,
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isVvip)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gradientStart,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'VVIP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isVvip)
                      IconButton(
                        onPressed: () => _openWhatsApp(phone),
                        icon: const Icon(
                          Icons.chat_rounded,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
