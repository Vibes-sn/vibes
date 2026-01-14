import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vibes/core/theme/app_theme.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({
    super.key,
    required this.eventTitle,
    required this.dateText,
    required this.location,
    required this.ticketId,
    required this.qrData,
  });

  final String eventTitle;
  final String dateText;
  final String location;
  final String ticketId;
  final String qrData;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _confetti.play();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 15,
              minBlastForce: 5,
              numberOfParticles: 24,
              gravity: 0.6,
              colors: const [
                Color(0xFFFF6FB1),
                Color(0xFFFF9F66),
                Color(0xFF00FFFF),
                Colors.white,
              ],
              emissionFrequency: 0.05,
            ),
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
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.greenAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'TICKET VALIDÉ !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prépare-toi pour ${widget.eventTitle} !',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _shine,
                          builder: (_, __) {
                            return _TicketCard(
                              eventTitle: widget.eventTitle,
                              dateText: widget.dateText,
                              location: widget.location,
                              ticketId: widget.ticketId,
                              qrData: widget.qrData,
                              shimmerValue: _shine.value,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
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
                          onPressed: () {},
                          child: const Text('Partager le ticket'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: AppColors.gradientStart,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ajouter à mon calendrier',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Partager sur Instagram'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Présente ce QR code à l\'entrée. Luminosité au max !',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.eventTitle,
    required this.dateText,
    required this.location,
    required this.ticketId,
    required this.qrData,
    required this.shimmerValue,
  });

  final String eventTitle;
  final String dateText;
  final String location;
  final String ticketId;
  final String qrData;
  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    final shimmerGradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.02),
        Colors.white.withValues(alpha: 0.10),
        Colors.white.withValues(alpha: 0.02),
      ],
      begin: Alignment(-2 + 4 * shimmerValue, -1),
      end: const Alignment(0, 0),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1470229538611-16ba8c7ffbd7?w=400',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        width: 60,
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
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
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 12),
              _infoRow('Nom du participant', 'Cheikh Diop'),
              const SizedBox(height: 8),
              _infoRow('Type de billet', 'PASS REGULAR'),
              const SizedBox(height: 8),
              _infoRow('Numéro de commande', ticketId),
              const SizedBox(height: 12),
              _infoRow('Heure de début', '22:00'),
              const SizedBox(height: 6),
              const Text(
                'Arrivée conseillée avant minuit',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        // Notches to mimic ticket cut
        Positioned(top: -10, left: -6, child: _Notch()),
        Positioned(top: -10, right: -6, child: _Notch()),
        Positioned(bottom: -10, left: -6, child: _Notch()),
        Positioned(bottom: -10, right: -6, child: _Notch()),
        // Shimmer overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: shimmerGradient,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 20,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}
