/// User model for local authentication
class AppUser {
  final String id;
  final String username;
  final String passwordHash; // Simple hash for demo purposes
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  /// Create from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Simple password hash (for demo - use proper hashing in production)
  static String hashPassword(String password) {
    // Simple hash for demo purposes
    int hash = 0;
    for (int i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Verify password
  bool verifyPassword(String password) {
    return passwordHash == hashPassword(password);
  }
}
