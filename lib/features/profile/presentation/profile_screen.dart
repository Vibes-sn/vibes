import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/services/auth_service.dart';
import 'package:vibes/core/state/user_provider.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/core/widgets/empty_state.dart';
import 'package:vibes/core/widgets/shimmer_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUpdatingRole = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserScope.of(context).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Connecte-toi pour accéder au profil.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final userProvider = UserScope.of(context);
    final role = userProvider.role;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profil'),
          actions: [
            IconButton(
              onPressed: () => userProvider.refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              onPressed: () => _openSettingsSheet(
                context,
                client: client,
                userProvider: userProvider,
                role: role,
                userId: user.id,
              ),
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _loadProfile(client, user.id),
                    builder: (context, snapshot) {
                      final profile = snapshot.data ?? const {};
                      final avatarUrl = profile['avatar_url'] as String?;
                      final fullName =
                          profile['full_name'] as String? ??
                          user.email?.split('@').first ??
                          'Viber';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.surface,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white70,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'SpaceGrotesk',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  role == 'host' ? 'Organisateur' : 'Viber',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (userProvider.isLoading) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Mise à jour du profil...',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<_ProfileStats>(
                    future: _loadStats(client, user.id),
                    builder: (context, snapshot) {
                      final stats =
                          snapshot.data ?? const _ProfileStats.empty();
                      return Row(
                        children: [
                          Expanded(
                            child: _StatChip(
                              label: 'Followers',
                              value: stats.followers,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatChip(
                              label: 'Following',
                              value: stats.following,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatChip(
                              label: 'Vibes',
                              value: stats.vibes,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: AppColors.gradientStart,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'Mes Billets'),
                Tab(text: 'Mes Souvenirs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TicketsTab(loadTickets: () => _loadTickets(client, user.id)),
                  _MemoriesTab(
                    loadMemories: () => _loadMemories(client, user.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadProfile(
    SupabaseClient client,
    String userId,
  ) async {
    final data = await client
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    return data;
  }

  Future<_ProfileStats> _loadStats(SupabaseClient client, String userId) async {
    try {
      final results = await Future.wait([
        client.from('follows').select('follower_id').eq('following_id', userId),
        client.from('follows').select('following_id').eq('follower_id', userId),
        client.from('vibes_stories').select('id').eq('user_id', userId),
      ]);
      final followers = (results[0] as List).length;
      final following = (results[1] as List).length;
      final vibes = (results[2] as List).length;
      return _ProfileStats(
        followers: followers,
        following: following,
        vibes: vibes,
      );
    } catch (_) {
      return const _ProfileStats.empty();
    }
  }

  Future<List<_TicketItem>> _loadTickets(
    SupabaseClient client,
    String userId,
  ) async {
    final data = await client
        .from('tickets')
        .select(
          'id, qr_code_data, status, event:events(title, event_date, location_name)',
        )
        .eq('user_id', userId)
        .order('purchase_date', ascending: false);
    final now = DateTime.now();
    final tickets = (data as List)
        .map((row) {
          final event = row['event'] as Map<String, dynamic>?;
          final eventDate = DateTime.tryParse(
            event?['event_date'] as String? ?? '',
          );
          return _TicketItem(
            id: row['id'] as String,
            qrData: row['qr_code_data'] as String,
            title: event?['title'] as String? ?? 'Événement à venir',
            location: event?['location_name'] as String? ?? 'Lieu à confirmer',
            eventDate: eventDate,
          );
        })
        .where(
          (ticket) =>
              ticket.eventDate == null || ticket.eventDate!.isAfter(now),
        )
        .toList();
    return tickets;
  }

  Future<List<_MemoryItem>> _loadMemories(
    SupabaseClient client,
    String userId,
  ) async {
    final data = await client
        .from('vibes_stories')
        .select('id, media_url, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map(
          (row) => _MemoryItem(
            id: row['id'] as String,
            mediaUrl: row['media_url'] as String?,
          ),
        )
        .toList();
  }

  Future<void> _openSettingsSheet(
    BuildContext context, {
    required SupabaseClient client,
    required UserProvider userProvider,
    required String role,
    required String userId,
  }) async {
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              if (role == 'host')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Passer en mode Organisateur',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Active le menu business',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    value: userProvider.organizerMode,
                    activeColor: AppColors.gradientStart,
                    onChanged: (value) {
                      userProvider.setOrganizerMode(value);
                      Navigator.of(context).pop();
                    },
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gradientStart,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      if (_isUpdatingRole) return;
                      HapticFeedback.lightImpact();
                      setState(() => _isUpdatingRole = true);
                      try {
                        _log('update role start user=$userId');
                        final newRole = await AuthService(
                          client: client,
                        ).toggleRole('host');
                        await userProvider.refresh();
                        if (newRole != 'host') {
                          _log('update role rejected newRole=$newRole');
                          _showFeedback(
                            'Mise à jour refusée par la base.',
                            isError: true,
                          );
                          return;
                        }
                        userProvider.setOrganizerMode(true);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        _showFeedback('Tu es maintenant Organisateur.');
                      } on PostgrestException catch (e) {
                        _log('update role postgrest error: ${e.message}');
                        if (!context.mounted) return;
                        _showFeedback(
                          'Erreur Supabase: ${e.message}',
                          isError: true,
                        );
                      } catch (e) {
                        _log('update role error: $e');
                        if (!context.mounted) return;
                        _showFeedback(
                          'Impossible de changer le rôle.',
                          isError: true,
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isUpdatingRole = false);
                        }
                      }
                    },
                    child: _isUpdatingRole
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Devenir Organisateur',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await client.auth.signOut();
                    userProvider.setOrganizerMode(false);
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    _showFeedback('Déconnecté avec succès.');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _log(String message) {
    debugPrint('[ProfileScreen] $message');
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({required this.loadTickets});

  final Future<List<_TicketItem>> Function() loadTickets;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_TicketItem>>(
      future: loadTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return const ShimmerBox(width: 260, height: 170);
            },
          );
        }
        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) {
          return EmptyState(
            title: 'Aucun ticket acheté',
            subtitle: 'Réserve ta prochaine soirée pour voir tes billets ici.',
            icon: Icons.confirmation_num_outlined,
            actionLabel: 'Découvrir les événements',
            onAction: () => Navigator.of(context).maybePop(),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          scrollDirection: Axis.horizontal,
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return _TicketCard(ticket: ticket);
          },
        );
      },
    );
  }
}

class _MemoriesTab extends StatelessWidget {
  const _MemoriesTab({required this.loadMemories});

  final Future<List<_MemoryItem>> Function() loadMemories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_MemoryItem>>(
      future: loadMemories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gradientStart),
          );
        }
        final memories = snapshot.data ?? [];
        if (memories.isEmpty) {
          return const Center(
            child: Text(
              'Tes souvenirs apparaîtront ici.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: memories.length,
          itemBuilder: (context, index) {
            final memory = memories[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: AppColors.surface,
                child: memory.mediaUrl == null
                    ? const Icon(Icons.photo, color: Colors.white24)
                    : Image.network(memory.mediaUrl!, fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final _TicketItem ticket;

  @override
  Widget build(BuildContext context) {
    final dateText = ticket.eventDate == null
        ? 'Date à confirmer'
        : DateFormat('EEE dd MMM', 'fr_FR').format(ticket.eventDate!);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.location,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            dateText,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: ticket.qrData,
                size: 110,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.followers,
    required this.following,
    required this.vibes,
  });

  const _ProfileStats.empty() : followers = 0, following = 0, vibes = 0;

  final int followers;
  final int following;
  final int vibes;
}

class _TicketItem {
  const _TicketItem({
    required this.id,
    required this.qrData,
    required this.title,
    required this.location,
    required this.eventDate,
  });

  final String id;
  final String qrData;
  final String title;
  final String location;
  final DateTime? eventDate;
}

class _MemoryItem {
  const _MemoryItem({required this.id, required this.mediaUrl});

  final String id;
  final String? mediaUrl;
}
