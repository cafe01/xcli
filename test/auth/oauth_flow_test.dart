import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:test/test.dart';
import 'package:xcli/src/auth/oauth_flow.dart';
import 'package:xcli/src/auth/pkce.dart';

void main() {
  group('OAuthFlow', () {
    group('buildAuthorizationUrl', () {
      test('includes required OAuth parameters', () {
        final flow = OAuthFlow(clientId: 'test-client-id');
        final result = flow.buildAuthorizationUrl();
        final uri = Uri.parse(result.url);

        expect(uri.host, 'x.com');
        expect(uri.path, '/i/oauth2/authorize');
        expect(uri.queryParameters['response_type'], 'code');
        expect(uri.queryParameters['client_id'], 'test-client-id');
        expect(uri.queryParameters['code_challenge_method'], 'S256');
        expect(uri.queryParameters['redirect_uri'], contains('localhost'));
      });

      test('includes PKCE code challenge', () {
        final flow = OAuthFlow(clientId: 'test-client-id');
        final result = flow.buildAuthorizationUrl();
        final uri = Uri.parse(result.url);

        // Verify the challenge matches the verifier
        final expectedChallenge = Pkce.generateCodeChallenge(
          result.codeVerifier,
        );
        expect(uri.queryParameters['code_challenge'], expectedChallenge);
      });

      test('includes state parameter', () {
        final flow = OAuthFlow(clientId: 'test-client-id');
        final result = flow.buildAuthorizationUrl();
        final uri = Uri.parse(result.url);

        expect(uri.queryParameters['state'], isNotEmpty);
        expect(result.state, uri.queryParameters['state']);
      });

      test('uses default scopes', () {
        final flow = OAuthFlow(clientId: 'test-client-id');
        final result = flow.buildAuthorizationUrl();
        final uri = Uri.parse(result.url);
        final scopes = uri.queryParameters['scope']!;

        expect(scopes, contains('tweet.read'));
        expect(scopes, contains('offline.access'));
        expect(scopes, contains('users.read'));
      });

      test('accepts custom scopes', () {
        final flow = OAuthFlow(clientId: 'test-client-id');
        final result = flow.buildAuthorizationUrl(
          scopes: ['tweet.read', 'users.read'],
        );
        final uri = Uri.parse(result.url);

        expect(uri.queryParameters['scope'], 'tweet.read users.read');
      });

      test('uses configured redirect port', () {
        final flow = OAuthFlow(clientId: 'test-client-id', redirectPort: 9999);
        final result = flow.buildAuthorizationUrl();
        final uri = Uri.parse(result.url);

        expect(uri.queryParameters['redirect_uri'], contains('9999'));
      });

      test('generates unique verifier and state per call', () {
        final flow = OAuthFlow(clientId: 'test-client-id');
        final a = flow.buildAuthorizationUrl();
        final b = flow.buildAuthorizationUrl();

        expect(a.codeVerifier, isNot(equals(b.codeVerifier)));
        expect(a.state, isNot(equals(b.state)));
      });
    });

    group('exchangeCode', () {
      test('sends correct token exchange request', () async {
        String? capturedBody;

        final mockClient = http_testing.MockClient((request) async {
          expect(request.url.toString(), OAuthFlow.tokenUrl);
          expect(
            request.headers['Content-Type'],
            'application/x-www-form-urlencoded',
          );
          capturedBody = request.body;

          return http.Response(
            jsonEncode(<String, dynamic>{
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'expires_in': 7200,
              'scope': 'tweet.read users.read',
            }),
            200,
          );
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        await flow.exchangeCode(code: 'auth-code', codeVerifier: 'verifier');

        expect(capturedBody, contains('grant_type=authorization_code'));
        expect(capturedBody, contains('code=auth-code'));
        expect(capturedBody, contains('code_verifier=verifier'));
        expect(capturedBody, contains('client_id=my-client'));
      });

      test('returns token on success', () async {
        final mockClient = http_testing.MockClient((_) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'access_token': 'the-access-token',
              'refresh_token': 'the-refresh-token',
              'expires_in': 7200,
              'scope': 'tweet.read users.read',
            }),
            200,
          );
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        final token = await flow.exchangeCode(
          code: 'code',
          codeVerifier: 'verifier',
        );

        expect(token.accessToken, 'the-access-token');
        expect(token.refreshToken, 'the-refresh-token');
        expect(token.scopes, ['tweet.read', 'users.read']);
        expect(token.isExpired, isFalse);
      });

      test('throws OAuthException on non-200 response', () async {
        final mockClient = http_testing.MockClient((_) async {
          return http.Response('{"error":"invalid_grant"}', 400);
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        expect(
          () => flow.exchangeCode(code: 'bad', codeVerifier: 'v'),
          throwsA(isA<OAuthException>()),
        );
      });
    });

    group('refreshToken', () {
      test('sends correct refresh request', () async {
        String? capturedBody;

        final mockClient = http_testing.MockClient((request) async {
          capturedBody = request.body;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'access_token': 'refreshed-access',
              'refresh_token': 'new-refresh',
              'expires_in': 7200,
              'scope': 'tweet.read',
            }),
            200,
          );
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        await flow.refreshToken('old-refresh-token');

        expect(capturedBody, contains('grant_type=refresh_token'));
        expect(capturedBody, contains('refresh_token=old-refresh-token'));
        expect(capturedBody, contains('client_id=my-client'));
      });

      test('returns new token on success', () async {
        final mockClient = http_testing.MockClient((_) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'access_token': 'refreshed-access',
              'refresh_token': 'new-refresh',
              'expires_in': 7200,
              'scope': 'tweet.read',
            }),
            200,
          );
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        final token = await flow.refreshToken('old-refresh');

        expect(token.accessToken, 'refreshed-access');
        expect(token.refreshToken, 'new-refresh');
      });

      test('throws OAuthException on failure', () async {
        final mockClient = http_testing.MockClient((_) async {
          return http.Response('{"error":"invalid_grant"}', 400);
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        expect(
          () => flow.refreshToken('bad-token'),
          throwsA(isA<OAuthException>()),
        );
      });
    });

    group('revokeToken', () {
      test('sends revocation request without throwing', () async {
        var called = false;
        final mockClient = http_testing.MockClient((request) async {
          called = true;
          expect(request.body, contains('token=some-token'));
          expect(request.body, contains('client_id=my-client'));
          return http.Response('', 200);
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        await flow.revokeToken('some-token');
        expect(called, isTrue);
      });

      test('does not throw on revocation failure', () async {
        final mockClient = http_testing.MockClient((_) async {
          return http.Response('server error', 500);
        });

        final flow = OAuthFlow(
          clientId: 'my-client',
          httpClient: mockClient,
        );

        // Should not throw
        await flow.revokeToken('any-token');
      });
    });

    group('waitForCallback', () {
      test('receives authorization code from callback', () async {
        // Use port 0 for OS-assigned port
        final flow = OAuthFlow(clientId: 'test', redirectPort: 0);
        final auth = flow.buildAuthorizationUrl();

        // Start listening in a separate future
        final server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final port = server.port;
        await server.close();

        // Use the port that was assigned
        final flow2 = OAuthFlow(clientId: 'test', redirectPort: port);
        final auth2 = flow2.buildAuthorizationUrl();

        final codeFuture = flow2.waitForCallback(
          expectedState: auth2.state,
          timeout: const Duration(seconds: 5),
        );

        // Simulate browser callback
        final client = http.Client();
        try {
          await client.get(
            Uri.parse(
              'http://localhost:$port/callback'
              '?code=test-auth-code&state=${auth2.state}',
            ),
          );
        } finally {
          client.close();
        }

        final code = await codeFuture;
        expect(code, 'test-auth-code');

        // Clean up unused flow/auth
        expect(auth.codeVerifier, isNotEmpty);
      });
    });
  });

  group('OAuthException', () {
    test('toString includes message', () {
      const exception = OAuthException('test error');
      expect(exception.toString(), 'OAuthException: test error');
    });

    test('message is accessible', () {
      const exception = OAuthException('details here');
      expect(exception.message, 'details here');
    });
  });
}
