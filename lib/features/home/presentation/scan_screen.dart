import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

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
          .select('id, status, user_id')
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
          name: result['user_id'] as String? ?? 'Utilisateur',
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
        name: result['user_id'] as String? ?? 'Utilisateur',
        message: 'TICKET VALIDE',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur scan: $e')));
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _controller.toggleTorch();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: const Text('Flash togglé')),
                    );
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
