import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/core/widgets/empty_state.dart';
import 'package:vibes/features/host/presentation/create_event_screen.dart';
import 'package:vibes/features/host/presentation/participants_screen.dart';
import 'package:vibes/features/home/presentation/scan_screen.dart';

enum HostSection { stats, events }

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({
    super.key,
    this.initialSection = HostSection.stats,
  });

  final HostSection initialSection;

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  late final SupabaseClient _client;
  late final User _user;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _eventsKey = GlobalKey();
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté.');
    }
    _user = user;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection() {
    final targetKey = widget.initialSection == HostSection.events
        ? _eventsKey
        : _statsKey;
    final context = targetKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<_HostStats> _loadStats() async {
    final tickets = await _client
        .from('tickets')
        .select('status, events!inner(price)')
        .eq('events.host_id', _user.id);

    int sold = 0;
    num revenue = 0;
    for (final t in tickets as List) {
      final status = t['status'] as String?;
      if (status == 'paid' || status == 'used') {
        sold++;
        final event = t['events'] as Map<String, dynamic>?;
        revenue += (event?['price'] ?? 0) as num;
      }
    }
    return _HostStats(
      ticketsSold: sold,
      revenue: revenue,
      vibesShared: 0, // placeholder: à relier à une table UGC
    );
  }

  Future<_SocialStats> _loadSocialStats() async {
    int likes = 0;
    int vibes = 0;
    try {
      final likesRows = await _client
          .from('event_likes')
          .select('id, events!inner(host_id)')
          .eq('events.host_id', _user.id);
      likes = (likesRows as List).length;
    } catch (_) {
      likes = 0;
    }
    try {
      final vibesRows = await _client
          .from('vibes_stories')
          .select('id, events!inner(host_id)')
          .eq('events.host_id', _user.id);
      vibes = (vibesRows as List).length;
    } catch (_) {
      vibes = 0;
    }
    return _SocialStats(likes: likes, vibes: vibes);
  }

  @override
  Widget build(BuildContext context) {
    final eventsStream = _client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('host_id', _user.id)
        .order('event_date', ascending: false);
    final priceFuture = _client
        .from('events')
        .select('id, price')
        .eq('host_id', _user.id);
    final ticketsStream = _client.from('tickets').stream(primaryKey: ['id']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard Organisateur')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gradientStart,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateEventScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            key: _statsKey,
            child: FutureBuilder<_HostStats>(
              future: _loadStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StatsSkeleton();
                }
                final stats =
                    snapshot.data ??
                    const _HostStats(
                      ticketsSold: 0,
                      revenue: 0,
                      vibesShared: 0,
                    );
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Tickets vendus',
                        value: stats.ticketsSold.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Revenus (FCFA)',
                        value: NumberFormat(
                          "#,###",
                          "fr_FR",
                        ).format(stats.revenue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Vibes partagées',
                        value: stats.vibesShared.toString(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Revenus en temps réel',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: priceFuture,
            builder: (context, priceSnapshot) {
              if (priceSnapshot.connectionState == ConnectionState.waiting) {
                return const _ChartSkeleton();
              }
              final priceMap = <String, num>{};
              for (final row in priceSnapshot.data ?? []) {
                priceMap[row['id'] as String] = (row['price'] ?? 0) as num;
              }
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: ticketsStream,
                builder: (context, snapshot) {
                  final tickets = snapshot.data ?? [];
                  final points = _buildSalesSeries(tickets, priceMap);
                  return _TicketSalesChart(points: points);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Performance Sociale',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<_SocialStats>(
            future: _loadSocialStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SocialSkeleton();
              }
              final stats =
                  snapshot.data ?? const _SocialStats(likes: 0, vibes: 0);
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Likes',
                      value: stats.likes.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Vibes (stories)',
                      value: stats.vibes.toString(),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Check-in mode',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _CheckinCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScanScreen(simplified: true),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _ActionCard(
            title: 'Liste des participants',
            subtitle: 'Voir qui a acheté quoi et contacter les VVIP',
            icon: Icons.list_alt_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParticipantsScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Mes événements',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: _eventsKey,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gradientStart,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Text(
                    'Erreur de chargement des événements.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return EmptyState(
                    title: 'Aucun événement créé',
                    subtitle: 'Crée ton premier événement pour commencer.',
                    icon: Icons.event_available_outlined,
                    actionLabel: 'Créer un événement',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateEventScreen(),
                        ),
                      );
                    },
                  );
                }
                return Column(
                  children: events.map((event) {
                    final isPublished = event['is_published'] == true;
                    return _EventRow(
                      isPublished: isPublished,
                      title: event['title'] as String? ?? 'Événement',
                      date: event['event_date'] as String?,
                      onPublish: isPublished
                          ? null
                          : () => _publishEvent(event['id'] as String),
                      onScan: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _publishEvent(String eventId) async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await _client
          .from('events')
          .update({'is_published': true})
          .eq('id', eventId)
          .eq('host_id', _user.id);
      _showFeedback('Événement publié.');
    } on PostgrestException catch (e) {
      _showFeedback('Erreur Supabase: ${e.message}', isError: true);
    } catch (_) {
      _showFeedback('Impossible de publier.', isError: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.title,
    required this.date,
    required this.onScan,
    required this.isPublished,
    this.onPublish,
  });

  final String title;
  final String? date;
  final VoidCallback onScan;
  final bool isPublished;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final dateText = date != null
        ? DateFormat("EEE d MMM • HH:mm", 'fr_FR').format(DateTime.parse(date!))
        : 'Date à venir';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onScan,
                child: const Text('Scanner les entrées'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPublished
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPublished ? 'Publié' : 'Brouillon',
                  style: TextStyle(
                    color: isPublished ? Colors.greenAccent : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (!isPublished && onPublish != null)
                TextButton(
                  onPressed: onPublish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gradientStart,
                  ),
                  child: const Text('Publier'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SkeletonBox()),
        SizedBox(width: 12),
        Expanded(child: _SkeletonBox()),
        SizedBox(width: 12),
        Expanded(child: _SkeletonBox()),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
    );
  }
}

List<double> _buildSalesSeries(
  List<Map<String, dynamic>> tickets,
  Map<String, num> priceMap,
) {
  final now = DateTime.now();
  final days = List.generate(
    7,
    (i) => DateTime(now.year, now.month, now.day - (6 - i)),
  );
  final buckets = List<double>.filled(7, 0);

  for (final ticket in tickets) {
    final status = ticket['status'] as String?;
    if (status != 'paid' && status != 'used') continue;
    final eventId = ticket['event_id'] as String?;
    if (eventId == null || !priceMap.containsKey(eventId)) continue;
    final rawDate = ticket['purchase_date'] as String?;
    if (rawDate == null) continue;
    final date = DateTime.tryParse(rawDate);
    if (date == null) continue;
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      if (date.year == day.year &&
          date.month == day.month &&
          date.day == day.day) {
        buckets[i] += 1;
        break;
      }
    }
  }
  return buckets;
}

class _TicketSalesChart extends StatelessWidget {
  const _TicketSalesChart({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                points.length,
                (i) => FlSpot(i.toDouble(), points[i]),
              ),
              isCurved: true,
              color: const Color(0xFFFF6FB1),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF6FB1).withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
    );
  }
}

class _SocialStats {
  const _SocialStats({required this.likes, required this.vibes});

  final int likes;
  final int vibes;
}

class _SocialSkeleton extends StatelessWidget {
  const _SocialSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SkeletonBox()),
        SizedBox(width: 12),
        Expanded(child: _SkeletonBox()),
      ],
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mode check-in rapide pour le staff',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onTap,
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _HostStats {
  const _HostStats({
    required this.ticketsSold,
    required this.revenue,
    required this.vibesShared,
  });

  final int ticketsSold;
  final num revenue;
  final int vibesShared;
}
