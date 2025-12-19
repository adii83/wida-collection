class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'super_admin', 'admin', 'moderator'
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'admin',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get canManageProducts => role == 'super_admin' || role == 'admin';
  bool get canManageOrders => true; // All admin roles can manage orders
}
