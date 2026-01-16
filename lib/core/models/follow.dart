class Follow {
  const Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  static const table = 'follows';
  static const colFollowerId = 'follower_id';
  static const colFollowingId = 'following_id';
  static const colCreatedAt = 'created_at';

  final String followerId;
  final String followingId;
  final DateTime createdAt;

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      followerId: map[colFollowerId] as String,
      followingId: map[colFollowingId] as String,
      createdAt:
          DateTime.tryParse(map[colCreatedAt] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
