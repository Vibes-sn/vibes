import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibes/core/theme/app_theme.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.simplified = false});

  final bool simplified;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  int scanned = 124;
  int capacity = 300;
  bool _showingDialog = false;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _ensureOrganizerAccess();
  }

  Future<void> _ensureOrganizerAccess() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _showFeedback(
        context,
        message: 'Connecte-toi pour scanner.',
        isError: true,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = profile?['role'] as String?;
      if (role != 'host' && role != 'pro') {
        _showFeedback(
          context,
          message: 'Accès réservé aux organisateurs.',
          isError: true,
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      _log('Erreur role scan: $e');
      _showFeedback(
        context,
        message: 'Impossible de vérifier tes droits.',
        isError: true,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    } finally {
      if (mounted) setState(() => _checkingRole = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_showingDialog) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null) return;
    _validateTicket(code);
  }

  Future<void> _validateTicket(String code) async {
    final client = Supabase.instance.client;
    try {
      final result = await client
          .from('tickets')
          .select('id, status, user_id, profiles(full_name)')
          .eq('qr_code_data', code)
          .maybeSingle();

      if (result == null) {
        await _showResultDialog(
          valid: false,
          alreadyUsed: false,
          name: 'Inconnu',
          message: 'TICKET INVALIDE',
        );
        return;
      }

      final status = result['status'] as String? ?? 'paid';
      if (status == 'used') {
        await _showResultDialog(
          valid: false,
          alreadyUsed: true,
          name: (result['profiles']?['full_name'] as String?) ?? 'Utilisateur',
          message: 'TICKET DÉJÀ VALIDÉ',
        );
        return;
      }

      await client
          .from('tickets')
          .update({'status': 'used'})
          .eq('id', result['id'] as String);

      await _showResultDialog(
        valid: true,
        alreadyUsed: false,
        name: (result['profiles']?['full_name'] as String?) ?? 'Utilisateur',
        message: 'TICKET VALIDE',
      );
    } catch (e) {
      _log('Erreur scan: $e');
      _showFeedback(
        context,
        message: 'Erreur de scan. Réessaie.',
        isError: true,
      );
    }
  }

  Future<void> _showResultDialog({
    required bool valid,
    required bool alreadyUsed,
    required String name,
    required String message,
  }) async {
    setState(() => _showingDialog = true);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: valid
              ? Colors.green.shade900
              : (alreadyUsed
                    ? Colors.red.shade900
                    : Colors.deepOrange.shade900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  valid
                      ? Icons.check_circle_rounded
                      : (alreadyUsed
                            ? Icons.error_rounded
                            : Icons.block_rounded),
                  color: Colors.white,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Suivant',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    setState(() => _showingDialog = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_checkingRole)
            MobileScanner(controller: _controller, onDetect: _handleBarcode),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          _CenterOverlay(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 12,
            right: 12,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                if (!widget.simplified) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        'Entrées : $scanned / $capacity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await _controller.toggleTorch();
                    if (!context.mounted) return;
                    _showFeedback(context, message: 'Flash togglé');
                  },
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
  debugPrint('[ScanScreen] $message');
}

class _CenterOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00FFFF), width: 3),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
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
