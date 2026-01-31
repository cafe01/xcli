import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'pkce.dart';
import 'token.dart';

/// OAuth 2.0 PKCE flow for X.com API v2.
///
/// Implements the full authorization code flow with PKCE:
/// 1. Generate PKCE challenge
/// 2. Open browser to authorization URL
/// 3. Listen for callback on localhost
/// 4. Exchange authorization code for tokens
class OAuthFlow {
  /// Creates an OAuth flow.
  ///
  /// [clientId] is the X Developer App's client ID.
  /// [redirectPort] is the localhost port for the callback server.
  /// [httpClient] is injectable for testing.
  OAuthFlow({
    required this.clientId,
    this.redirectPort = 8914,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// X Developer App client ID (public client, no secret needed for PKCE).
  final String clientId;

  /// Localhost port for OAuth callback.
  final int redirectPort;

  final http.Client _httpClient;

  /// X.com OAuth 2.0 authorization endpoint.
  static const authorizationUrl = 'https://x.com/i/oauth2/authorize';

  /// X.com OAuth 2.0 token endpoint.
  static const tokenUrl = 'https://api.x.com/2/oauth2/token';

  /// X.com OAuth 2.0 token revocation endpoint.
  static const revokeUrl = 'https://api.x.com/2/oauth2/revoke';

  /// Default scopes covering all XApi operations + offline refresh.
  static const defaultScopes = [
    'tweet.read',
    'tweet.write',
    'users.read',
    'follows.read',
    'follows.write',
    'like.read',
    'like.write',
    'bookmark.read',
    'bookmark.write',
    'block.read',
    'block.write',
    'mute.read',
    'mute.write',
    'list.read',
    'list.write',
    'offline.access',
  ];

  String get _redirectUri => 'http://localhost:$redirectPort/callback';

  /// Build the authorization URL for the browser.
  ///
  /// Returns a record with the URL, code verifier, and state parameter.
  ({String url, String codeVerifier, String state}) buildAuthorizationUrl({
    List<String>? scopes,
  }) {
    final codeVerifier = Pkce.generateCodeVerifier();
    final codeChallenge = Pkce.generateCodeChallenge(codeVerifier);
    final state = Pkce.generateCodeVerifier(43);

    final params = <String, String>{
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': _redirectUri,
      'scope': (scopes ?? defaultScopes).join(' '),
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final uri = Uri.parse(authorizationUrl).replace(queryParameters: params);
    return (url: uri.toString(), codeVerifier: codeVerifier, state: state);
  }

  /// Start a local HTTP server to receive the OAuth callback.
  ///
  /// Returns the authorization code from the callback.
  /// Throws [OAuthException] on error or timeout.
  Future<String> waitForCallback({
    required String expectedState,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    HttpServer server;
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        redirectPort,
      );
    } on SocketException catch (e) {
      throw OAuthException(
        'Could not start callback server on port $redirectPort: $e',
      );
    }

    final completer = Completer<String>();

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          OAuthException(
            'Authorization timed out after ${timeout.inMinutes} minutes.',
          ),
        );
      }
    });

    final subscription = server.listen((request) async {
      if (request.uri.path == '/callback') {
        final code = request.uri.queryParameters['code'];
        final state = request.uri.queryParameters['state'];
        final error = request.uri.queryParameters['error'];

        if (error != null) {
          _sendResponse(request, 'Authorization denied: $error');
          if (!completer.isCompleted) {
            completer.completeError(
              OAuthException('Authorization denied: $error'),
            );
          }
        } else if (state != expectedState) {
          _sendResponse(request, 'State mismatch. Please try again.');
          if (!completer.isCompleted) {
            completer.completeError(
              const OAuthException('OAuth state mismatch (possible CSRF).'),
            );
          }
        } else if (code == null) {
          _sendResponse(request, 'No authorization code received.');
          if (!completer.isCompleted) {
            completer.completeError(
              const OAuthException('No authorization code in callback.'),
            );
          }
        } else {
          _sendResponse(
            request,
            'Authorization successful! You can close this tab.',
          );
          if (!completer.isCompleted) {
            completer.complete(code);
          }
        }
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found');
        await request.response.close();
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      await server.close();
    }
  }

  void _sendResponse(HttpRequest request, String message) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(
        '<!DOCTYPE html>'
        '<html><body style="font-family:system-ui;text-align:center;'
        'padding:2em;">'
        '<h2>$message</h2>'
        '<p>Return to your terminal.</p>'
        '</body></html>',
      );
    unawaited(request.response.close());
  }

  /// Exchange an authorization code for access + refresh tokens.
  ///
  /// Throws [OAuthException] on failure.
  Future<OAuthToken> exchangeCode({
    required String code,
    required String codeVerifier,
  }) async {
    final response = await _httpClient.post(
      Uri.parse(tokenUrl),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException(
        'Token exchange failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expiresIn = json['expires_in'] as int;

    return OAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      scopes: (json['scope'] as String?)?.split(' ') ?? const [],
    );
  }

  /// Refresh an expired access token using a refresh token.
  ///
  /// Returns a new [OAuthToken] with updated credentials.
  /// Throws [OAuthException] on failure.
  Future<OAuthToken> refreshToken(String refreshToken) async {
    final response = await _httpClient.post(
      Uri.parse(tokenUrl),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException(
        'Token refresh failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expiresIn = json['expires_in'] as int;

    return OAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      scopes: (json['scope'] as String?)?.split(' ') ?? const [],
    );
  }

  /// Revoke a token (access or refresh). Best-effort, does not throw.
  Future<void> revokeToken(String token) async {
    try {
      await _httpClient.post(
        Uri.parse(revokeUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'token': token,
          'client_id': clientId,
          'token_type_hint': 'access_token',
        },
      );
    } on Exception {
      // Best-effort revocation -- do not propagate failures.
    }
  }

  /// Open a URL in the system browser. Returns true on success.
  static Future<bool> openBrowser(String url) async {
    try {
      final String command;
      final List<String> args;

      if (Platform.isMacOS) {
        command = 'open';
        args = [url];
      } else if (Platform.isLinux) {
        command = 'xdg-open';
        args = [url];
      } else if (Platform.isWindows) {
        command = 'cmd';
        args = ['/c', 'start', url];
      } else {
        return false;
      }

      final result = await Process.run(command, args);
      return result.exitCode == 0;
    } on Exception {
      return false;
    }
  }
}

/// Exception thrown during OAuth operations.
class OAuthException implements Exception {
  /// Creates an OAuth exception.
  const OAuthException(this.message);

  /// Descriptive error message.
  final String message;

  @override
  String toString() => 'OAuthException: $message';
}
