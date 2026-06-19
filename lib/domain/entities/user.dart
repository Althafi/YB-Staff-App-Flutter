class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String token;
  final String? phone;
  final String? avatarUrl;

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? token,
    String? phone,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role &&
          token == other.token;

  @override
  int get hashCode => Object.hash(id, email, role, token);
}
