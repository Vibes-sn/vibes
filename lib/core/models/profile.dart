class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.role,
    required this.phone,
    required this.isVerified,
    required this.createdAt,
  });

  static const table = 'profiles';
  static const colId = 'id';
  static const colFullName = 'full_name';
  static const colAvatarUrl = 'avatar_url';
  static const colRole = 'role';
  static const colPhone = 'phone';
  static const colIsVerified = 'is_verified';
  static const colCreatedAt = 'created_at';

  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String? phone;
  final bool isVerified;
  final DateTime createdAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map[colId] as String,
      fullName: map[colFullName] as String?,
      avatarUrl: map[colAvatarUrl] as String?,
      role: map[colRole] as String? ?? 'viber',
      phone: map[colPhone] as String?,
      isVerified: map[colIsVerified] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map[colCreatedAt] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      colId: id,
      colFullName: fullName,
      colAvatarUrl: avatarUrl,
      colRole: role,
      colPhone: phone,
      colIsVerified: isVerified,
      colCreatedAt: createdAt.toIso8601String(),
    };
  }
}
