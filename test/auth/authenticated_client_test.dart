import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:test/test.dart';
import 'package:xcli/src/auth/authenticated_client.dart';
import 'package:xcli/src/auth/oauth_flow.dart';
import 'package:xcli/src/auth/token.dart';
import 'package:xcli/src/auth/token_store.dart';

void main() {
  late Directory tempDir;
  late TokenStore tokenStore;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('xcli_auth_client_test_');
    tokenStore = TokenStore(configDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  OAuthToken makeToken({
    String accessToken = 'access-123',
    Duration expiresIn = const Duration(hours: 2),
  }) =>
      OAuthToken(
        accessToken: accessToken,
        refreshToken: 'refresh-456',
        expiresAt: DateTime.now().add(expiresIn),
        username: 'testuser',
        userId: '789',
        scopes: ['tweet.read'],
      );

  group('AuthenticatedClient', () {
    test('injects Bearer token into requests', () async {
      tokenStore.saveToken('default', makeToken());

      String? capturedAuth;
      final innerClient = http_testing.MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });

      // OAuthFlow with mock client (unused in this test since token is fresh)
      final oauthFlow = OAuthFlow(
        clientId: 'test',
        httpClient: http_testing.MockClient((_) async {
          return http.Response('', 500);
        }),
      );

      final client = AuthenticatedClient(
        tokenStore: tokenStore,
        oauthFlow: oauthFlow,
        inner: innerClient,
      );

      await client.get(Uri.parse('https://api.x.com/2/tweets/123'));
      client.close();

      expect(capturedAuth, 'Bearer access-123');
    });

    test('sends request without token when not logged in', () async {
      String? capturedAuth;
      final innerClient = http_testing.MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });

      final oauthFlow = OAuthFlow(
        clientId: 'test',
        httpClient: http_testing.MockClient((_) async {
          return http.Response('', 500);
        }),
      );

      final client = AuthenticatedClient(
        tokenStore: tokenStore,
        oauthFlow: oauthFlow,
        inner: innerClient,
      );

      await client.get(Uri.parse('https://api.x.com/2/tweets/123'));
      client.close();

      expect(capturedAuth, isNull);
    });

    test('refreshes expired token before request', () async {
      // Save a token that's about to expire
      final expiringToken = makeToken(
        accessToken: 'old-access',
        expiresIn: const Duration(minutes: 1), // within refresh buffer
      );
      tokenStore.saveToken('default', expiringToken);

      String? capturedAuth;
      final innerClient = http_testing.MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });

      final oauthFlow = OAuthFlow(
        clientId: 'test',
        httpClient: http_testing.MockClient((_) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'access_token': 'refreshed-access',
              'refresh_token': 'new-refresh',
              'expires_in': 7200,
              'scope': 'tweet.read',
            }),
            200,
          );
        }),
      );

      final client = AuthenticatedClient(
        tokenStore: tokenStore,
        oauthFlow: oauthFlow,
        inner: innerClient,
      );

      await client.get(Uri.parse('https://api.x.com/2/tweets/123'));
      client.close();

      expect(capturedAuth, 'Bearer refreshed-access');

      // Verify the refreshed token was persisted
      final stored = tokenStore.getToken('default');
      expect(stored!.accessToken, 'refreshed-access');
    });

    test('uses existing token when refresh fails', () async {
      final expiringToken = makeToken(
        accessToken: 'stale-access',
        expiresIn: const Duration(minutes: 1),
      );
      tokenStore.saveToken('default', expiringToken);

      String? capturedAuth;
      final innerClient = http_testing.MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });

      // Refresh fails
      final oauthFlow = OAuthFlow(
        clientId: 'test',
        httpClient: http_testing.MockClient((_) async {
          return http.Response('{"error":"invalid_grant"}', 400);
        }),
      );

      final client = AuthenticatedClient(
        tokenStore: tokenStore,
        oauthFlow: oauthFlow,
        inner: innerClient,
      );

      await client.get(Uri.parse('https://api.x.com/2/tweets/123'));
      client.close();

      // Should fall back to the stale token
      expect(capturedAuth, 'Bearer stale-access');
    });

    test('preserves username and userId through refresh', () async {
      final expiringToken = OAuthToken(
        accessToken: 'old',
        refreshToken: 'old-refresh',
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
        username: 'myuser',
        userId: '12345',
        scopes: ['tweet.read'],
      );
      tokenStore.saveToken('default', expiringToken);

      final innerClient = http_testing.MockClient((_) async {
        return http.Response('{}', 200);
      });

      final oauthFlow = OAuthFlow(
        clientId: 'test',
        httpClient: http_testing.MockClient((_) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'access_token': 'new',
              'refresh_token': 'new-refresh',
              'expires_in': 7200,
              'scope': 'tweet.read',
            }),
            200,
          );
        }),
      );

      final client = AuthenticatedClient(
        tokenStore: tokenStore,
        oauthFlow: oauthFlow,
        inner: innerClient,
      );

      await client.get(Uri.parse('https://api.x.com/2/test'));
      client.close();

      final stored = tokenStore.getToken('default');
      expect(stored!.username, 'myuser');
      expect(stored.userId, '12345');
    });
  });
}
