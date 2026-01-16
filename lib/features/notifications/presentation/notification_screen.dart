import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final SupabaseClient _client;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Connecte-toi pour voir tes notifications.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gradientStart),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Aucune notification pour le moment.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final items = data.map(_NotificationItem.fromMap).toList();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _NotificationTile(item: item);
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (_) {}
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final isSocial = item.type == _NotificationType.social;
    final icon = isSocial ? Icons.favorite_rounded : Icons.confirmation_num;
    final iconColor = isSocial
        ? AppColors.gradientStart
        : AppColors.gradientEnd;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        item.message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _relativeTime(item.createdAt),
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'À l’instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} j';
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory _NotificationItem.fromMap(Map<String, dynamic> map) {
    final typeValue = map['type'] as String? ?? 'social';
    return _NotificationItem(
      id: map['id'] as String,
      type: typeValue == 'transactional'
          ? _NotificationType.transactional
          : _NotificationType.social,
      message: map['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  final String id;
  final _NotificationType type;
  final String message;
  final DateTime createdAt;
  final bool isRead;
}

enum _NotificationType { social, transactional }
