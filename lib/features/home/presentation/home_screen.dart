import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/home/data/event_model.dart';
import 'package:vibes/features/home/data/event_repository.dart';
import 'package:vibes/features/home/presentation/widgets/event_card.dart';
import 'package:vibes/features/home/presentation/widgets/vibes_bottom_nav.dart';
import 'package:vibes/features/home/presentation/widgets/vibes_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});

  final EventRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final EventRepository _repository;
  late Future<List<EventModel>> _eventsFuture;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat("EEE d MMM • HH:mm", 'fr_FR');
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EventRepository();
    _eventsFuture = _repository.fetchPublishedEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = _repository.fetchPublishedEvents();
    });
    await _eventsFuture;
  }

  List<EventModel> _filter(List<EventModel> events) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return events;
    return events
        .where(
          (e) =>
              e.title.toLowerCase().contains(query) ||
              e.locationName.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _Header(onNotificationTap: () {}),
              const SizedBox(height: 12),
              VibesSearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<EventModel>>(
                  future: _eventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gradientStart,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        onRetry: _refresh,
                        message: 'Oups, impossible de charger les événements.',
                      );
                    }
                    final events = snapshot.data ?? [];
                    final filtered = _filter(events);

                    if (filtered.isEmpty) {
                      return _EmptyState(onRefresh: _refresh);
                    }

                    return RefreshIndicator(
                      color: AppColors.gradientStart,
                      onRefresh: _refresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => EventCard(
                          event: filtered[index],
                          dateFormat: _dateFormat,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: VibesBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/vibes-logo-magenta-ori.png',
              height: 40,
              fit: BoxFit.contain,
              semanticLabel: 'Vibes',
            ),
            const SizedBox(height: 4),
            Text(
              'Découvre les meilleures nuits',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.gradientStart,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Aucun événement trouvé',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.message});

  final Future<void> Function() onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.black,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
