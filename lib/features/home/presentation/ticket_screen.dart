import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibes/core/theme/app_theme.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({
    super.key,
    required this.eventTitle,
    required this.dateText,
    required this.location,
    required this.ticketId,
    required this.qrData,
    this.eventImageUrl,
    this.ticketType = 'PASS VIP',
    this.holderName = 'Viber',
    this.status = 'paid',
    this.locationAddress,
  });

  final String eventTitle;
  final String dateText;
  final String location;
  final String ticketId;
  final String qrData;
  final String? eventImageUrl;
  final String ticketType;
  final String holderName;
  final String status;
  final String? locationAddress;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final GlobalKey _captureKey = GlobalKey();
  String _status = 'paid';
  String _holderName = 'Viber';
  StreamSubscription<List<Map<String, dynamic>>>? _ticketSub;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _status = widget.status;
    _holderName = widget.holderName;
    _loadTicketMeta();
    _listenTicketStatus();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUsed = _status == 'used';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          _TicketHeader(
                            title: widget.eventTitle,
                            ticketType: widget.ticketType,
                            imageUrl: widget.eventImageUrl,
                          ),
                          const SizedBox(height: 18),
                          RepaintBoundary(
                            key: _captureKey,
                            child: Stack(
                              children: [
                                _TicketCard(
                                  dateText: widget.dateText,
                                  location: widget.location,
                                  locationAddress: widget.locationAddress,
                                  ticketId: widget.ticketId,
                                  holderName: _holderName,
                                  qrData: widget.qrData,
                                  pulse: _pulse,
                                ),
                                if (isUsed)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          child: const Text(
                                            'UTILISÉ',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _GradientButton(
                          label: 'Ouvrir l’itinéraire',
                          onTap: () => _openMaps(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _saveTicketToGallery(context),
                          child: const Text('Enregistrer en image'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTicketMeta() async {
    final client = Supabase.instance.client;
    try {
      final ticket = await client
          .from('tickets')
          .select('status, user_id')
          .eq('id', widget.ticketId)
          .maybeSingle();
      if (ticket == null) return;
      final status = ticket['status'] as String? ?? _status;
      final userId = ticket['user_id'] as String?;
      if (userId == null) {
        if (mounted) setState(() => _status = status);
        return;
      }
      final profile = await client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _status = status;
        _holderName = profile?['full_name'] as String? ?? _holderName;
      });
    } catch (_) {
      // Keep fallback values if supabase read fails.
    }
  }

  void _listenTicketStatus() {
    _ticketSub = Supabase.instance.client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('id', widget.ticketId)
        .listen((rows) {
          if (rows.isEmpty || !mounted) return;
          final status = rows.first['status'] as String?;
          if (status == null) return;
          setState(() => _status = status);
        });
  }

  Future<void> _openMaps(BuildContext context) async {
    HapticFeedback.lightImpact();
    final query = Uri.encodeComponent(
      '${widget.location} ${widget.locationAddress ?? ''}'.trim(),
    );
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir Maps')));
  }

  Future<void> _saveTicketToGallery(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export image non supporté sur Web')),
      );
      return;
    }
    final granted = await _ensureGalleryPermission();
    if (!granted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission galerie requise')),
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de capturer le ticket')),
      );
      return;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final result = await ImageGallerySaver.saveImage(
      Uint8List.fromList(bytes),
      quality: 100,
      name: 'vibes_ticket_${widget.ticketId}',
    );
    if (!context.mounted) return;
    final success = (result['isSuccess'] == true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ticket enregistré dans la galerie'
              : 'Erreur de sauvegarde',
        ),
      ),
    );
  }

  Future<bool> _ensureGalleryPermission() async {
    final PermissionStatus status;
    if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.storage.request();
    }
    return status.isGranted || status.isLimited;
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.dateText,
    required this.location,
    required this.locationAddress,
    required this.ticketId,
    required this.holderName,
    required this.qrData,
    required this.pulse,
  });

  final String dateText;
  final String location;
  final String? locationAddress;
  final String ticketId;
  final String holderName;
  final String qrData;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1.02).animate(
                    CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientStart.withValues(alpha: 0.2),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.3,
                children: [
                  _InfoTile(label: 'Date & heure', value: dateText),
                  _InfoTile(
                    label: 'Lieu',
                    value: locationAddress?.isNotEmpty == true
                        ? '$location\n$locationAddress'
                        : location,
                  ),
                  _InfoTile(label: 'Détenteur', value: holderName),
                  _InfoTile(label: 'ID Ticket', value: ticketId),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: -10,
          top: 140,
          child: _Notch(color: AppColors.background),
        ),
        Positioned(
          right: -10,
          top: 140,
          child: _Notch(color: AppColors.background),
        ),
      ],
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({
    required this.title,
    required this.ticketType,
    this.imageUrl,
  });

  final String title;
  final String ticketType;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.network(
            imageUrl ??
                'https://images.unsplash.com/photo-1470229538611-16ba8c7ffbd7?w=1200',
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(height: 170, color: Colors.white12),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
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
                  ticketType,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
