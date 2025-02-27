class User {
  final int id;
  final String name;
  final String username;
  final String password;
  final String role;
  final DateTime createdAt;
  final int? synced;
  final int? companyId;
  final String email;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
    this.synced,
    this.companyId,
    required this.email,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: json['synced'] as int?,
      companyId: json['company_id'] as int?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'synced': synced,
      'company_id': companyId,
      'email': email,
      'phone': phone,
    };
  }
}
