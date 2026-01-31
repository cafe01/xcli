/// OAuth 2.0 token credentials for an authenticated X.com account.
class OAuthToken {
  /// Creates an OAuth token.
  const OAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.username,
    this.userId,
    this.scopes = const [],
  });

  /// Creates a token from a JSON map (as stored on disk).
  factory OAuthToken.fromJson(Map<String, dynamic> json) {
    return OAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      username: json['username'] as String?,
      userId: json['user_id'] as String?,
      scopes: (json['scopes'] as List<dynamic>?)
              ?.map((dynamic s) => s as String)
              .toList() ??
          const [],
    );
  }

  /// Bearer access token.
  final String accessToken;

  /// Refresh token for obtaining new access tokens.
  final String refreshToken;

  /// When the access token expires.
  final DateTime expiresAt;

  /// X.com username associated with this token (resolved post-login).
  final String? username;

  /// X.com user ID associated with this token (resolved post-login).
  final String? userId;

  /// Scopes granted to this token.
  final List<String> scopes;

  /// Whether the access token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the access token expires within [duration].
  bool expiresWithin(Duration duration) =>
      DateTime.now().add(duration).isAfter(expiresAt);

  /// Serialize to JSON map for disk storage.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
        if (username != null) 'username': username,
        if (userId != null) 'user_id': userId,
        'scopes': scopes,
      };

  /// Returns a copy with updated fields.
  OAuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? username,
    String? userId,
    List<String>? scopes,
  }) {
    return OAuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      username: username ?? this.username,
      userId: userId ?? this.userId,
      scopes: scopes ?? this.scopes,
    );
  }
}
