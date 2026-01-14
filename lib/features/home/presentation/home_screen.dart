import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/home/data/event_model.dart';
import 'package:vibes/features/home/presentation/event_details_screen.dart';
import 'package:vibes/features/home/presentation/scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat("EEE d MMM • HH:mm", 'fr_FR');
  int _navIndex = 0;
  late final Stream<List<Map<String, dynamic>>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('is_published', true)
        .order('event_date');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 30,
                          child: Image.asset(
                            'assets/images/vibes-logo-white-ori.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Découvre les meilleures nuits',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gradientStart,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Erreur de chargement',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data ?? [];
                  final events = data.map((e) => EventModel.fromMap(e)).where((
                    e,
                  ) {
                    final q = _searchController.text.trim().toLowerCase();
                    if (q.isEmpty) return true;
                    return e.title.toLowerCase().contains(q) ||
                        e.locationName.toLowerCase().contains(q);
                  }).toList();

                  if (events.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Aucun événement disponible',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == events.length - 1 ? 0 : 14,
                        ),
                        child: _EventCard(
                          event: event,
                          dateFormat: _dateFormat,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailsScreen(event: event),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
            return;
          }
          setState(() => _navIndex = index);
        },
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.gradientStart,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Chercher une soirée...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.dateFormat,
    required this.onTap,
  });

  final EventModel event;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Hero(
                tag: 'event-hero-${event.id}',
                child: Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white12,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.price <= 0
                      ? 'Gratuit'
                      : '${NumberFormat("#,###", "fr_FR").format(event.price)} FCFA',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateFormat.format(event.eventDate),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
