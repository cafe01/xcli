/// Minimal user data class for typed access to common fields.
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    this.description,
    this.verified,
  });

  /// Parse from X API v2 user object.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      description: json['description'] as String?,
      verified: json['verified'] as bool?,
    );
  }

  final String id;
  final String name;
  final String username;
  final String? description;
  final bool? verified;
}
