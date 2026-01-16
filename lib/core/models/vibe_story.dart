class VibeStory {
  const VibeStory({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  static const table = 'vibes_stories';
  static const colId = 'id';
  static const colUserId = 'user_id';
  static const colEventId = 'event_id';
  static const colMediaUrl = 'media_url';
  static const colCreatedAt = 'created_at';
  static const colExpiresAt = 'expires_at';

  final String id;
  final String userId;
  final String? eventId;
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  factory VibeStory.fromMap(Map<String, dynamic> map) {
    return VibeStory(
      id: map[colId] as String,
      userId: map[colUserId] as String,
      eventId: map[colEventId] as String?,
      mediaUrl: map[colMediaUrl] as String? ?? '',
      createdAt:
          DateTime.tryParse(map[colCreatedAt] as String? ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(map[colExpiresAt] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
