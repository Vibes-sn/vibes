import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/theme/app_theme.dart';

class VibeCreator extends StatefulWidget {
  const VibeCreator({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.locationName,
  });

  final String eventId;
  final String eventTitle;
  final String locationName;

  @override
  State<VibeCreator> createState() => _VibeCreatorState();
}

class _VibeCreatorState extends State<VibeCreator> {
  CameraController? _controller;
  bool _initializing = true;
  bool _recording = false;
  bool _saving = false;
  XFile? _captured;
  _CaptureMode _mode = _CaptureMode.photo;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.isNotEmpty ? cameras.first : null;
      if (camera == null) {
        if (mounted) setState(() => _initializing = false);
        return;
      }
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _controller!.initialize();
    } catch (_) {
      // ignore for UI fallback
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final file = await _controller!.takePicture();
    setState(() => _captured = file);
  }

  Future<void> _toggleRecord() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_recording) {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _recording = false;
        _captured = file;
      });
      return;
    }
    await _controller!.startVideoRecording();
    setState(() => _recording = true);
  }

  Future<String?> _uploadToStorage(XFile file, String userId) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_vibe.$ext';
    final bucket = Supabase.instance.client.storage.from('vibes-stories');
    if (kIsWeb) {
      await bucket.uploadBinary(path, bytes);
    } else {
      await bucket.upload(path, File(file.path));
    }
    return bucket.getPublicUrl(path);
  }

  Future<void> _publish() async {
    if (_captured == null || _saving) return;
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        _showFeedback('Connecte-toi pour publier.', isError: true);
        return;
      }
      final url = await _uploadToStorage(_captured!, user.id);
      if (url == null) {
        _showFeedback('Upload impossible.', isError: true);
        return;
      }
      final mediaType = _mode == _CaptureMode.photo ? 'photo' : 'video';
      await client.from('vibes_stories').insert({
        'event_id': widget.eventId,
        'user_id': user.id,
        'media_url': url,
        'media_type': mediaType,
        'event_title': widget.eventTitle,
        'location_name': widget.locationName,
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      });
      if (!mounted) return;
      _showFeedback('Vibe publiée !');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showFeedback('Publication impossible.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    final preview = _controller != null && _controller!.value.isInitialized
        ? CameraPreview(_controller!)
        : Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Caméra indisponible',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _captured == null
                  ? Stack(
                      children: [
                        preview,
                        if (_initializing)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gradientStart,
                            ),
                          ),
                      ],
                    )
                  : _CapturedView(
                      file: _captured!,
                      isVideo: _mode == _CaptureMode.video,
                    ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _captured == null
                  ? Column(
                      children: [
                        _StickerBadge(
                          title: widget.eventTitle,
                          location: widget.locationName,
                        ),
                        const SizedBox(height: 12),
                        _ModeSwitch(
                          mode: _mode,
                          onChanged: (mode) => setState(() => _mode = mode),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_mode == _CaptureMode.photo)
                              _CaptureButton(
                                onTap: _takePhoto,
                                recording: false,
                              )
                            else
                              _CaptureButton(
                                onTap: _toggleRecord,
                                recording: _recording,
                              ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => setState(() => _captured = null),
                            child: const Text('Reprendre'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gradientStart,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _saving ? null : _publish,
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Publier la Vibe',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CaptureMode { photo, video }

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final _CaptureMode mode;
  final ValueChanged<_CaptureMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: 'Photo',
            active: mode == _CaptureMode.photo,
            onTap: () => onChanged(_CaptureMode.photo),
          ),
          _ModeChip(
            label: 'Vidéo',
            active: mode == _CaptureMode.video,
            onTap: () => onChanged(_CaptureMode.video),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap, required this.recording});

  final VoidCallback onTap;
  final bool recording;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66,
        width: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? Colors.redAccent : Colors.white,
        ),
      ),
    );
  }
}

class _StickerBadge extends StatelessWidget {
  const _StickerBadge({required this.title, required this.location});

  final String title;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
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
            const SizedBox(height: 2),
            Text(
              location,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturedView extends StatelessWidget {
  const _CapturedView({required this.file, required this.isVideo});

  final XFile file;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Aperçu indisponible en web',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }
    if (isVideo) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
        ),
      );
    }
    return Image.file(File(file.path), fit: BoxFit.cover);
  }
}
