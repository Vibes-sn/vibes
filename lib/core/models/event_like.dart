class EventLike {
  const EventLike({
    required this.userId,
    required this.eventId,
    required this.createdAt,
  });

  static const table = 'event_likes';
  static const colUserId = 'user_id';
  static const colEventId = 'event_id';
  static const colCreatedAt = 'created_at';

  final String userId;
  final String eventId;
  final DateTime createdAt;

  factory EventLike.fromMap(Map<String, dynamic> map) {
    return EventLike(
      userId: map[colUserId] as String,
      eventId: map[colEventId] as String,
      createdAt:
          DateTime.tryParse(map[colCreatedAt] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
