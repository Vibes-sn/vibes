import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibes/core/state/user_provider.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/core/widgets/shimmer_box.dart';
import 'package:vibes/features/home/data/event_model.dart';
import 'package:vibes/features/home/presentation/event_details_screen.dart';
import 'package:vibes/features/home/presentation/friends_screen.dart';
import 'package:vibes/features/home/presentation/my_tickets_screen.dart';
import 'package:vibes/features/home/presentation/scan_screen.dart';
import 'package:vibes/features/host/presentation/host_dashboard_screen.dart';
import 'package:vibes/features/notifications/presentation/notification_screen.dart';
import 'package:vibes/features/profile/presentation/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _prefCategory = 'home_category';
  static const _prefDateFilter = 'home_date_filter';
  static const _prefDateValue = 'home_date_value';
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat("EEE d MMM • HH:mm", 'fr_FR');
  final DateFormat _shortDate = DateFormat('EEE dd MMM', 'fr_FR');
  int _navIndex = 0;
  late final Stream<List<Map<String, dynamic>>> _eventsStream;
  final List<_CategoryFilter> _categories = const [
    _CategoryFilter(value: 'all', label: '🔥 Tout', keywords: []),
    _CategoryFilter(
      value: 'clubbing',
      label: '🕺 Clubbing',
      keywords: ['club', 'dj', 'party', 'night', 'soiree'],
    ),
    _CategoryFilter(
      value: 'concerts',
      label: '🎤 Concerts',
      keywords: ['concert', 'live', 'show', 'stage'],
    ),
    _CategoryFilter(
      value: 'lounge',
      label: '🍸 Lounge',
      keywords: ['lounge', 'rooftop', 'cocktail', 'bar'],
    ),
    _CategoryFilter(
      value: 'expos',
      label: '🎨 Expos',
      keywords: ['expo', 'gallery', 'art', 'exposition'],
    ),
  ];
  String _selectedCategory = 'all';
  _DateFilterType _dateFilter = _DateFilterType.all;
  DateTime? _selectedDate;
  final List<_StoryItem> _stories = const [
    _StoryItem(
      'Awa',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      isNew: true,
    ),
    _StoryItem(
      'Moussa',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      isNew: false,
    ),
    _StoryItem(
      'Khadija',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
      isNew: true,
    ),
    _StoryItem(
      'Issa',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=200',
      isNew: false,
    ),
    _StoryItem(
      'Lina',
      'https://images.unsplash.com/photo-1502767089025-6572583495b0?w=200',
      isNew: true,
    ),
  ];
  final List<_SocialFeedItem> _socialFeed = const [
    _SocialFeedItem(
      title: 'Dakar Neon Night',
      location: 'Phare des Mamelles',
      friends: ['Awa', 'Moussa'],
      count: 15,
    ),
    _SocialFeedItem(
      title: 'Afro Heat Session',
      location: 'Almadies',
      friends: ['Khadija', 'Issa'],
      count: 9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _eventsStream = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('is_published', true)
        .order('event_date');
    _loadFilters();
  }

  List<_NavItem> get _navItems {
    final userProvider = UserScope.of(context);
    final organizerMode = userProvider.organizerMode;
    final isHost = userProvider.isHost;
    final useHostTabs = organizerMode && isHost;
    if (useHostTabs) {
      return const [
        _NavItem(icon: Icons.bar_chart_rounded, label: 'Tableau'),
        _NavItem(icon: Icons.event_note_rounded, label: 'Événements'),
        _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scanner'),
        _NavItem(icon: Icons.person_rounded, label: 'Profil'),
      ];
    }
    return const [
      _NavItem(icon: Icons.explore_rounded, label: 'Découvrir'),
      _NavItem(icon: Icons.group_rounded, label: 'Mes Amis'),
      _NavItem(icon: Icons.confirmation_num_rounded, label: 'Mes Tickets'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems;
    if (_navIndex >= navItems.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _navIndex = 0);
      });
    }
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
                    Row(
                      children: [
                        _NotificationsButton(
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (UserScope.of(context).organizerMode &&
                            UserScope.of(context).isHost)
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.person_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _CategoryChips(
                        categories: _categories,
                        selected: _selectedCategory,
                        onSelected: (value) {
                          setState(() => _selectedCategory = value);
                          _saveFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _DateFilterButton(
                      label: _dateFilterLabel(),
                      onTap: () => _openDateFilter(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Vibes (24h)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Partage une story liée à un événement',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _StoriesBar(stories: _stories),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feed social',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _socialFeed
                          .map((item) => _SocialFeedCard(item: item))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: List.generate(
                            3,
                            (index) => const Padding(
                              padding: EdgeInsets.only(bottom: 14),
                              child: ShimmerBox(
                                width: double.infinity,
                                height: 170,
                              ),
                            ),
                          ),
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
                  final events = data
                      .map((e) => EventModel.fromMap(e))
                      .where((e) {
                        final q = _searchController.text.trim().toLowerCase();
                        if (q.isEmpty) return true;
                        final matchesQuery =
                            e.title.toLowerCase().contains(q) ||
                            e.locationName.toLowerCase().contains(q) ||
                            (e.description?.toLowerCase().contains(q) ?? false);
                        return matchesQuery;
                      })
                      .where((e) {
                        return _matchesCategory(e);
                      })
                      .where((e) {
                        return _matchesDate(e.eventDate);
                      })
                      .toList();

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

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${events.length} événements',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      final event = events[index - 1];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == events.length ? 0 : 14,
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
                    }, childCount: events.length + 1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _VibesBottomBar(
        items: navItems,
        currentIndex: _navIndex,
        onTap: (index) => _handleTabTap(context, index),
      ),
    );
  }

  void _handleTabTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    final userProvider = UserScope.of(context);
    final isHost = userProvider.isHost;
    final organizerMode = userProvider.organizerMode;
    final useHostTabs = organizerMode && isHost;

    if (useHostTabs) {
      if (index == 0) {
        setState(() => _navIndex = index);
        _pushTab(
          context,
          const HostDashboardScreen(initialSection: HostSection.stats),
        );
        return;
      }
      if (index == 1) {
        setState(() => _navIndex = index);
        _pushTab(
          context,
          const HostDashboardScreen(initialSection: HostSection.events),
        );
        return;
      }
      if (index == 2) {
        setState(() => _navIndex = index);
        _pushTab(context, const ScanScreen());
        return;
      }
      if (index == 3) {
        setState(() => _navIndex = index);
        _pushTab(context, const ProfileScreen());
        return;
      }
    } else {
      if (index == 0) {
        setState(() => _navIndex = 0);
        return;
      }
      if (index == 1) {
        setState(() => _navIndex = index);
        _pushTab(context, const FriendsScreen());
        return;
      }
      if (index == 2) {
        setState(() => _navIndex = index);
        _pushTab(context, const MyTicketsScreen());
        return;
      }
      if (index == 3) {
        setState(() => _navIndex = index);
        _pushTab(context, const ProfileScreen());
        return;
      }
    }
  }

  void _pushTab(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: page),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  bool _matchesCategory(EventModel event) {
    if (_selectedCategory == 'all') return true;
    final categoryValue = event.category?.toLowerCase();
    return categoryValue == _selectedCategory;
  }

  bool _matchesDate(DateTime eventDate) {
    if (_dateFilter == _DateFilterType.all) return true;
    final now = DateTime.now();
    if (_dateFilter == _DateFilterType.tonight) {
      return _isSameDay(eventDate, now);
    }
    if (_dateFilter == _DateFilterType.weekend) {
      final range = _currentWeekendRange(now);
      return eventDate.isAfter(range.start) && eventDate.isBefore(range.end);
    }
    if (_dateFilter == _DateFilterType.specific && _selectedDate != null) {
      return _isSameDay(eventDate, _selectedDate!);
    }
    return true;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  _DateRange _currentWeekendRange(DateTime now) {
    final weekday = now.weekday;
    final daysToSaturday = (DateTime.saturday - weekday) % 7;
    final saturday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: daysToSaturday));
    final sunday = saturday.add(
      const Duration(days: 1, hours: 23, minutes: 59),
    );
    return _DateRange(start: saturday, end: sunday);
  }

  String _dateFilterLabel() {
    switch (_dateFilter) {
      case _DateFilterType.tonight:
        return 'Ce soir';
      case _DateFilterType.weekend:
        return 'Ce week-end';
      case _DateFilterType.specific:
        if (_selectedDate == null) return 'Calendrier';
        return _shortDate.format(_selectedDate!);
      case _DateFilterType.all:
        return 'Calendrier';
    }
  }

  Future<void> _openDateFilter(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              _DateOptionTile(
                title: 'Tout',
                selected: _dateFilter == _DateFilterType.all,
                onTap: () {
                  setState(() {
                    _dateFilter = _DateFilterType.all;
                    _selectedDate = null;
                  });
                  _saveFilters();
                  Navigator.of(ctx).pop();
                },
              ),
              _DateOptionTile(
                title: 'Ce soir',
                selected: _dateFilter == _DateFilterType.tonight,
                onTap: () {
                  setState(() {
                    _dateFilter = _DateFilterType.tonight;
                    _selectedDate = null;
                  });
                  _saveFilters();
                  Navigator.of(ctx).pop();
                },
              ),
              _DateOptionTile(
                title: 'Ce week-end',
                selected: _dateFilter == _DateFilterType.weekend,
                onTap: () {
                  setState(() {
                    _dateFilter = _DateFilterType.weekend;
                    _selectedDate = null;
                  });
                  _saveFilters();
                  Navigator.of(ctx).pop();
                },
              ),
              _DateOptionTile(
                title: 'Choisir une date',
                selected: _dateFilter == _DateFilterType.specific,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    helpText: 'Sélectionner une date',
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.gradientStart,
                            surface: AppColors.background,
                          ),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                  if (picked == null) return;
                  setState(() {
                    _dateFilter = _DateFilterType.specific;
                    _selectedDate = picked;
                  });
                  _saveFilters();
                  if (!context.mounted) return;
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final category = prefs.getString(_prefCategory);
    final dateFilter = prefs.getString(_prefDateFilter);
    final dateValue = prefs.getString(_prefDateValue);
    setState(() {
      _selectedCategory = category ?? 'all';
      _dateFilter = _parseDateFilter(dateFilter);
      _selectedDate = dateValue != null ? DateTime.tryParse(dateValue) : null;
      if (_dateFilter != _DateFilterType.specific) {
        _selectedDate = null;
      }
    });
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCategory, _selectedCategory);
    await prefs.setString(_prefDateFilter, _dateFilter.name);
    if (_dateFilter == _DateFilterType.specific && _selectedDate != null) {
      await prefs.setString(_prefDateValue, _selectedDate!.toIso8601String());
    } else {
      await prefs.remove(_prefDateValue);
    }
  }

  _DateFilterType _parseDateFilter(String? value) {
    for (final type in _DateFilterType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return _DateFilterType.all;
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

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _VibesBottomBar extends StatelessWidget {
  const _VibesBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? Colors.white : Colors.white60,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return IconButton(
        onPressed: onOpen,
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
        ),
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final unread = data
            .where((item) => (item['is_read'] as bool?) != true)
            .length;
        return IconButton(
          onPressed: onOpen,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
              ),
              if (unread > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<_CategoryFilter> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isActive = item.value == selected;
          return ChoiceChip(
            label: Text(item.label),
            selected: isActive,
            onSelected: (_) => onSelected(item.value),
            selectedColor: AppColors.gradientStart.withValues(alpha: 0.22),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isActive ? AppColors.gradientStart : Colors.white12,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateOptionTile extends StatelessWidget {
  const _DateOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.gradientStart)
          : const Icon(Icons.circle_outlined, color: Colors.white24),
    );
  }
}

class _CategoryFilter {
  const _CategoryFilter({
    required this.value,
    required this.label,
    required this.keywords,
  });

  final String value;
  final String label;
  final List<String> keywords;
}

enum _DateFilterType { all, tonight, weekend, specific }

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _StoriesBar extends StatefulWidget {
  const _StoriesBar({required this.stories});

  final List<_StoryItem> stories;

  @override
  State<_StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<_StoriesBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return Column(
            children: [
              _AnimatedStoryRing(
                controller: _controller,
                isNew: story.isNew,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white10,
                  backgroundImage: NetworkImage(story.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(
                  story.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          );
        },
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
    final mockFriends = const [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'https://images.unsplash.com/photo-1502767089025-6572583495b0?w=200',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
    ];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          height: 26,
                          width: 70,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (int i = 0; i < mockFriends.length; i++)
                                Positioned(
                                  left: i * 16,
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Colors.white10,
                                    backgroundImage: NetworkImage(
                                      mockFriends[i],
                                    ),
                                    onBackgroundImageError: (_, __) {},
                                    child: const Icon(
                                      Icons.person,
                                      size: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '15 amis y vont',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: Colors.white70,
                          size: 16,
                        ),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _IconAction(
                          icon: Icons.favorite_border_rounded,
                          label: 'Vibe',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vibe envoyée !')),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _IconAction(
                          icon: Icons.share_rounded,
                          label: 'Partager',
                          onTap: () => _shareEvent(context, event),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryItem {
  const _StoryItem(this.name, this.avatarUrl, {required this.isNew});
  final String name;
  final String avatarUrl;
  final bool isNew;
}

class _AnimatedStoryRing extends StatelessWidget {
  const _AnimatedStoryRing({
    required this.controller,
    required this.isNew,
    required this.child,
  });

  final AnimationController controller;
  final bool isNew;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isNew) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white12,
        ),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: controller.value * 2 * pi,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                  AppColors.gradientStart,
                ],
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _SocialFeedItem {
  const _SocialFeedItem({
    required this.title,
    required this.location,
    required this.friends,
    required this.count,
  });

  final String title;
  final String location;
  final List<String> friends;
  final int count;
}

Future<void> _shareEvent(BuildContext context, EventModel event) async {
  final message =
      'Rejoins-moi à ${event.title} sur Vibes: https://vibes.app/e/${event.id}';
  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  if (!await canLaunchUrl(url)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d’ouvrir WhatsApp.')),
    );
    return;
  }
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

class _SocialFeedCard extends StatelessWidget {
  const _SocialFeedCard({required this.item});

  final _SocialFeedItem item;

  @override
  Widget build(BuildContext context) {
    final friendText = item.friends.join(', ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, color: Color(0xFF00FFFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$friendText et ${item.count} autres vont à ${item.title} • ${item.location}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
