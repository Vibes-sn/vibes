import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:vibes/features/home/data/event_model.dart';
import 'package:vibes/features/home/presentation/ticket_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final lineup = [
      _Artist(
        'DJ Nova',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
      ),
      _Artist(
        'Kali Beats',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
      ),
      _Artist(
        'Luna Waves',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
      ),
      _Artist(
        'Tiko',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      ),
    ];

    final friends = [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'https://images.unsplash.com/photo-1502767089025-6572583495b0?w=200',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=200',
    ];

    final dateText = DateFormat(
      "EEE d MMM • HH:mm",
      'fr_FR',
    ).format(event.eventDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(event: event, dateText: dateText),
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
                          onTap: () => _showSnack(
                            context,
                            'Ouverture de la carte simulée',
                          ),
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
          _BottomBar(price: event.price, event: event),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _GlassButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _showSnack(context, 'Partage à venir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.dateText});

  final EventModel event;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.4;
    return SizedBox(
      height: height,
      child: Stack(
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
                    Text(
                      dateText,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
  const _BottomBar({required this.price, required this.event});

  final num price;
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
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
                      'À partir de',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price <= 0
                          ? 'Gratuit'
                          : '${NumberFormat("#,###", "fr_FR").format(price)} FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
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
                      final client = Supabase.instance.client;
                      final user = client.auth.currentUser;
                      final messenger = ScaffoldMessenger.of(context);
                      if (user == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Connectez-vous pour réserver.'),
                          ),
                        );
                        return;
                      }

                      // Vérifier le numéro de téléphone du profil
                      String? phone;
                      try {
                        final profile = await client
                            .from('profiles')
                            .select('phone_number')
                            .eq('id', user.id)
                            .maybeSingle();
                        phone = profile?['phone_number'] as String?;
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erreur profil: $e')),
                        );
                        return;
                      }

                      if (!context.mounted) return;

                      if (phone == null || phone.trim().isEmpty) {
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
                                    MediaQuery.of(context).viewInsets.bottom +
                                    16,
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
                                        backgroundColor:
                                            AppColors.gradientStart,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        final value = controller.text.trim();
                                        if (value.isEmpty) return;
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
                          return;
                        }

                        try {
                          await client
                              .from('profiles')
                              .update({'phone_number': phone.trim()})
                              .eq('id', user.id);
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Erreur enregistrement numéro: $e'),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                      }

                      final qrCode = 'VBS-${const Uuid().v4()}';
                      try {
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

                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 350,
                            ),
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
                        messenger.showSnackBar(
                          SnackBar(content: Text('Réservation impossible: $e')),
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
                      child: const Center(
                        child: Text(
                          'Réserver ma place',
                          style: TextStyle(
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
      ),
    );
  }
}

class _Artist {
  _Artist(this.name, this.photo);
  final String name;
  final String photo;
}
