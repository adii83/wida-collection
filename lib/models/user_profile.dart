class UserProfile {
  final String id; // same as auth.users.id
  final String username;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final String? phone;
  final String? fcmToken;
  final String role; // 'user' or 'admin'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.phone,
    this.fcmToken,
    this.role = 'user',
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '',
      fullName: (map['full_name'] as String?) ?? '',
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
      fcmToken: map['fcm_token'] as String?,
      role: (map['role'] as String?) ?? 'user',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (fcmToken != null) 'fcm_token': fcmToken,
      'role': role,
    };
  }

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? phone,
    String? fcmToken,
    String? role,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
