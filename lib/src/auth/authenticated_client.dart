import 'package:http/http.dart' as http;

import 'oauth_flow.dart';
import 'token.dart';
import 'token_store.dart';

/// HTTP client that injects Bearer tokens and handles automatic refresh.
///
/// Wraps a standard [http.Client] with token management:
/// - Reads the active token from [TokenStore]
/// - Refreshes tokens proactively before expiry via [OAuthFlow]
/// - Injects `Authorization: Bearer <token>` header into all requests
///
/// Future [XApi] implementations will use this as their HTTP transport.
class AuthenticatedClient extends http.BaseClient {
  /// Creates an authenticated client.
  ///
  /// [tokenStore] provides token persistence.
  /// [oauthFlow] enables automatic token refresh.
  /// [inner] is the underlying HTTP client (injectable for testing).
  AuthenticatedClient({
    required this.tokenStore,
    required this.oauthFlow,
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  /// Token persistence layer.
  final TokenStore tokenStore;

  /// OAuth flow for token refresh.
  final OAuthFlow oauthFlow;

  final http.Client _inner;

  /// Buffer before actual expiry to trigger proactive refresh.
  static const refreshBuffer = Duration(minutes: 5);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _getValidToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }
    return _inner.send(request);
  }

  /// Get a valid (non-expired) token, refreshing if needed.
  Future<OAuthToken?> _getValidToken() async {
    final account = tokenStore.activeAccount;
    if (account == null) return null;

    var token = tokenStore.getToken(account);
    if (token == null) return null;

    if (token.expiresWithin(refreshBuffer)) {
      try {
        final refreshed = await oauthFlow.refreshToken(token.refreshToken);
        token = refreshed.copyWith(
          username: token.username,
          userId: token.userId,
        );
        tokenStore.saveToken(account, token, setActive: false);
      } on OAuthException {
        // Refresh failed -- return existing token, let API call surface the
        // auth error so the caller can prompt re-authentication.
      }
    }

    return token;
  }

  @override
  void close() {
    _inner.close();
  }
}
