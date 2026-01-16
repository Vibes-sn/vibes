import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/home/data/event_model.dart';
import 'package:vibes/features/home/presentation/ticket_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.event});

  final EventModel event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final List<_TicketOption> _ticketOptions;
  late final Map<String, int> _quantities;
  late final Future<EventModel> _eventFuture;
  final DateTime _screenOpenedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _log('open details screen eventId=${widget.event.id}');
    _ticketOptions = const [
      _TicketOption(label: 'Regular', price: 10000),
      _TicketOption(label: 'VIP', price: 25000),
      _TicketOption(label: 'Table VVIP', price: 150000),
    ];
    _quantities = {for (final option in _ticketOptions) option.label: 0};
    _eventFuture = _fetchEvent();
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_screenOpenedAt);
    _log('close details screen after ${duration.inSeconds}s');
    super.dispose();
  }

  num get _totalPrice {
    num total = 0;
    for (final option in _ticketOptions) {
      total += option.price * (_quantities[option.label] ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    _log('build details screen');
    final lineup = [
      _Artist(
        'DJ Nova',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
        '@dj_nova',
      ),
      _Artist(
        'Kali Beats',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
        '@kali_beats',
      ),
      _Artist(
        'Luna Waves',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
        '@luna_waves',
      ),
      _Artist(
        'Tiko',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
        '@tiko_music',
      ),
    ];

    final friends = [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'https://images.unsplash.com/photo-1502767089025-6572583495b0?w=200',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=200',
    ];

    return FutureBuilder<EventModel>(
      future: _eventFuture,
      builder: (context, snapshot) {
        _log(
          'event load state=${snapshot.connectionState} '
          'hasData=${snapshot.hasData} hasError=${snapshot.hasError}',
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DetailsLoading();
        }
        if (snapshot.hasError) {
          return _DetailsError(message: 'Erreur de chargement de l’événement.');
        }
        final event = snapshot.data ?? widget.event;
        final dateText = DateFormat(
          "EEE d MMM • HH:mm",
          'fr_FR',
        ).format(event.eventDate);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: MediaQuery.of(context).size.height * 0.4,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: _GlassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      _log('tap back');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: _GlassButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () {
                        _log('tap share');
                        _showSnack(context, 'Partage à venir');
                      },
                    ),
                  ),
                ],
                flexibleSpace: _Header(event: event, dateText: dateText),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: const Color(0xFF00FFFF),
                            size: 18,
                            shadows: const [
                              Shadow(
                                color: Color.fromARGB(120, 0, 255, 255),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateText,
                            style: const TextStyle(
                              color: Color(0xFFE8ECF5),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _log('tap location row');
                            _showSnack(
                              context,
                              'Ouverture de la carte simulée',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  color: const Color(0xFF00FFFF),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    event.locationName,
                                    style: const TextStyle(
                                      color: Color(0xFFE8ECF5),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Le Line-up',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 132,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: lineup.isEmpty ? 1 : lineup.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            if (lineup.isEmpty) {
                              return const SizedBox(
                                width: 140,
                                child: Text(
                                  'Line-up à venir',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              );
                            }
                            final artist = lineup[index];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gradientStart
                                            .withValues(alpha: 0.25),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: NetworkImage(artist.photo),
                                    onBackgroundImageError: (_, __) {},
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 78,
                                  child: Text(
                                    artist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFE8ECF5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    artist.handle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'À propos',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (event.description?.isNotEmpty ?? false)
                            ? event.description!
                            : 'Description à venir. Prépare-toi à vivre une nuit unique.',
                        style: const TextStyle(
                          color: Color(0xFFE8ECF5),
                          height: 1.45,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Choisir vos billets',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TicketSelector(
                        options: _ticketOptions,
                        quantities: _quantities,
                        onUpdate: (label, qty) {
                          _log('ticket qty change label=$label qty=$qty');
                          setState(() => _quantities[label] = qty);
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Informations pratiques',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _InfoIconsRow(),
                      const SizedBox(height: 24),
                      const Text(
                        'Localisation',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LocationCard(
                        locationName: event.locationName,
                        onTap: () {
                          _log('tap map button');
                          _showFeedback(
                            context,
                            message: 'Ouverture de Maps...',
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Ils y vont',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 40,
                            width: 120,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (
                                  int i = 0;
                                  i < friends.length.clamp(0, 4);
                                  i++
                                )
                                  Positioned(
                                    left: i * 22,
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white10,
                                      backgroundImage: NetworkImage(friends[i]),
                                      onBackgroundImageError: (_, __) {},
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white54,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              '+12 amis y participent',
                              style: TextStyle(
                                color: Color(0xFFE8ECF5),
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomBar(
            totalPrice: _totalPrice,
            event: event,
            hasSelection: _totalPrice > 0,
          ),
        );
      },
    );
  }

  Future<EventModel> _fetchEvent() async {
    final client = Supabase.instance.client;
    _log('fetch event from supabase id=${widget.event.id}');
    final data = await client
        .from('events')
        .select()
        .eq('id', widget.event.id)
        .single();
    _log('fetch event success');
    return EventModel.fromMap(data);
  }

  void _showSnack(BuildContext context, String message) {
    _showFeedback(context, message: message);
  }
}

void _showFeedback(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isError
                ? [Colors.red.shade900, Colors.red.shade700]
                : const [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isError ? Colors.red : AppColors.gradientStart)
                  .withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _log(String message) {
  debugPrint('[EventDetails] $message');
}

class _DetailsLoading extends StatelessWidget {
  const _DetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.gradientStart),
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.dateText});

  final EventModel event;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'event-hero-${event.id}',
          child: Image.network(event.imageUrl, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(0, 0, 0, 0),
                  Color.fromARGB(64, 0, 0, 0),
                  Color.fromARGB(178, 0, 0, 0),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Color(0xFF00FFFF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(dateText, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.totalPrice,
    required this.event,
    required this.hasSelection,
  });

  final num totalPrice;
  final EventModel event;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalPrice <= 0
                        ? '0 FCFA'
                        : '${NumberFormat("#,###", "fr_FR").format(totalPrice)} FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Frais de service inclus',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    _log(
                      'tap reserve total=$totalPrice '
                      'hasSelection=$hasSelection',
                    );
                    final client = Supabase.instance.client;
                    final user = client.auth.currentUser;
                    if (user == null) {
                      _log('reserve blocked: no user');
                      _showFeedback(
                        context,
                        message: 'Connectez-vous pour réserver.',
                        isError: true,
                      );
                      return;
                    }
                    if (!hasSelection) {
                      _log('reserve blocked: no ticket selected');
                      _showFeedback(
                        context,
                        message: 'Choisis au moins un billet.',
                        isError: true,
                      );
                      return;
                    }

                    // Empêcher un double achat pour le même event
                    try {
                      _log('check existing ticket');
                      final existing = await client
                          .from('tickets')
                          .select('id, status')
                          .eq('event_id', event.id)
                          .eq('user_id', user.id)
                          .filter('status', 'in', '("paid","used")')
                          .maybeSingle();
                      if (existing != null) {
                        _log('reserve blocked: existing ticket');
                        _showFeedback(
                          context,
                          message: 'Tu as déjà un ticket pour cet événement.',
                          isError: true,
                        );
                        return;
                      }
                    } catch (e) {
                      _log('Erreur vérification ticket existant: $e');
                      _showFeedback(
                        context,
                        message: 'Impossible de vérifier ton ticket.',
                        isError: true,
                      );
                      return;
                    }

                    // Vérifier la capacité si disponible
                    if (event.capacity != null) {
                      try {
                        _log('check capacity');
                        final tickets = await client
                            .from('tickets')
                            .select('id')
                            .eq('event_id', event.id)
                            .filter('status', 'in', '("paid","used")');
                        final count = (tickets as List).length;
                        if (count >= event.capacity!) {
                          _log('reserve blocked: capacity full');
                          _showFeedback(
                            context,
                            message: 'Événement complet.',
                            isError: true,
                          );
                          return;
                        }
                      } catch (e) {
                        _log('Erreur capacité: $e');
                        _showFeedback(
                          context,
                          message: 'Impossible de vérifier la capacité.',
                          isError: true,
                        );
                        return;
                      }
                    }

                    // Vérifier le numéro de téléphone du profil
                    String? phone;
                    try {
                      _log('load profile phone');
                      final profile = await client
                          .from('profiles')
                          .select('phone_number')
                          .eq('id', user.id)
                          .maybeSingle();
                      if (profile == null) {
                        final fallbackName =
                            (user.userMetadata?['full_name'] as String?) ??
                            (user.email?.split('@').first ?? 'Viber');
                        _log('profile missing: create fallback');
                        await client.from('profiles').upsert({
                          'id': user.id,
                          'full_name': fallbackName,
                        });
                        _log('Profil créé manquant id=${user.id}');
                        phone = null;
                      } else {
                        phone = profile['phone_number'] as String?;
                      }
                    } catch (e) {
                      _log('Erreur profil: $e');
                      _showFeedback(
                        context,
                        message: 'Impossible de récupérer ton profil.',
                        isError: true,
                      );
                      return;
                    }

                    if (!context.mounted) return;

                    if (phone == null || phone.trim().isEmpty) {
                      _log('phone missing: prompt modal');
                      phone = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          final controller = TextEditingController();
                          return Container(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 16,
                              top: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              border: Border(
                                top: BorderSide(color: Colors.white10),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quel est ton numéro Wave / Orange Money ?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Ex: 77 123 45 67',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.gradientStart,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gradientStart,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      final value = controller.text.trim();
                                      if (value.isEmpty) return;
                                      _log('phone submitted: $value');
                                      Navigator.of(context).pop(value);
                                    },
                                    child: const Text(
                                      'Continuer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      if (phone == null || phone.trim().isEmpty) {
                        _log('reserve blocked: phone empty');
                        return;
                      }

                      try {
                        _log('save phone to profile');
                        await client
                            .from('profiles')
                            .update({'phone_number': phone.trim()})
                            .eq('id', user.id);
                      } catch (e) {
                        _log('Erreur enregistrement numéro: $e');
                        _showFeedback(
                          context,
                          message: 'Erreur lors de l’enregistrement du numéro.',
                          isError: true,
                        );
                        return;
                      }
                      if (!context.mounted) return;
                    }

                    final qrCode = 'VBS-${const Uuid().v4()}';
                    try {
                      _log('insert ticket');
                      final response = await client
                          .from('tickets')
                          .insert({
                            'event_id': event.id,
                            'user_id': user.id,
                            'qr_code_data': qrCode,
                          })
                          .select('id, qr_code_data')
                          .single();
                      final ticketId = response['id'] as String;
                      final qrData = response['qr_code_data'] as String;
                      _log('ticket created id=$ticketId');

                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder: (_, animation, __) => SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: TicketScreen(
                              eventTitle: event.title,
                              dateText: DateFormat(
                                "EEE d MMM • HH:mm",
                                'fr_FR',
                              ).format(event.eventDate),
                              location: event.locationName,
                              ticketId: ticketId,
                              qrData: qrData,
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      _log('Réservation impossible: $e');
                      _showFeedback(
                        context,
                        message: 'Réservation impossible, réessaie.',
                        isError: true,
                      );
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientStart.withValues(
                            alpha: 0.45,
                          ),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Réserver ma place',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Artist {
  _Artist(this.name, this.photo, this.handle);
  final String name;
  final String photo;
  final String handle;
}

class _TicketOption {
  const _TicketOption({required this.label, required this.price});
  final String label;
  final int price;
}

class _TicketSelector extends StatelessWidget {
  const _TicketSelector({
    required this.options,
    required this.quantities,
    required this.onUpdate,
  });

  final List<_TicketOption> options;
  final Map<String, int> quantities;
  final void Function(String label, int quantity) onUpdate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = options[index];
          final qty = quantities[option.label] ?? 0;
          return Container(
            width: 190,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${NumberFormat("#,###", "fr_FR").format(option.price)} FCFA',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: qty > 0
                          ? () => onUpdate(option.label, qty - 1)
                          : null,
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () => onUpdate(option.label, qty + 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _InfoIconsRow extends StatelessWidget {
  const _InfoIconsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _InfoIcon(icon: Icons.local_parking_rounded, label: 'Parking'),
        _InfoIcon(icon: Icons.ac_unit_rounded, label: 'Clim'),
        _InfoIcon(icon: Icons.smoking_rooms_rounded, label: 'Fumeur'),
        _InfoIcon(icon: Icons.shield_rounded, label: 'Sécurité'),
      ],
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: const Color(0xFF00FFFF)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.locationName, required this.onTap});

  final String locationName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1502920514313-52581002a659?w=1200',
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              color: Colors.white12,
              alignment: Alignment.center,
              child: const Icon(
                Icons.map_outlined,
                color: Colors.white54,
                size: 32,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    locationName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Itinéraire'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
