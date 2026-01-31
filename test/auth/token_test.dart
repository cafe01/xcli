import 'package:test/test.dart';
import 'package:xcli/src/auth/token.dart';

void main() {
  group('OAuthToken', () {
    final futureDate = DateTime.now().add(const Duration(hours: 2));
    final pastDate = DateTime.now().subtract(const Duration(hours: 1));

    OAuthToken makeToken({DateTime? expiresAt}) => OAuthToken(
          accessToken: 'access-123',
          refreshToken: 'refresh-456',
          expiresAt: expiresAt ?? futureDate,
          username: 'testuser',
          userId: '789',
          scopes: ['tweet.read', 'users.read'],
        );

    test('stores all fields', () {
      final token = makeToken();
      expect(token.accessToken, 'access-123');
      expect(token.refreshToken, 'refresh-456');
      expect(token.expiresAt, futureDate);
      expect(token.username, 'testuser');
      expect(token.userId, '789');
      expect(token.scopes, ['tweet.read', 'users.read']);
    });

    test('isExpired is false for future date', () {
      final token = makeToken();
      expect(token.isExpired, isFalse);
    });

    test('isExpired is true for past date', () {
      final token = makeToken(expiresAt: pastDate);
      expect(token.isExpired, isTrue);
    });

    test('expiresWithin returns true when within buffer', () {
      final soonDate = DateTime.now().add(const Duration(minutes: 3));
      final token = makeToken(expiresAt: soonDate);
      expect(token.expiresWithin(const Duration(minutes: 5)), isTrue);
    });

    test('expiresWithin returns false when outside buffer', () {
      final token = makeToken(); // 2 hours from now
      expect(token.expiresWithin(const Duration(minutes: 5)), isFalse);
    });

    group('serialization', () {
      test('toJson produces valid map', () {
        final token = makeToken();
        final json = token.toJson();

        expect(json['access_token'], 'access-123');
        expect(json['refresh_token'], 'refresh-456');
        expect(json['expires_at'], isA<String>());
        expect(json['username'], 'testuser');
        expect(json['user_id'], '789');
        expect(json['scopes'], ['tweet.read', 'users.read']);
      });

      test('fromJson restores token', () {
        final original = makeToken();
        final json = original.toJson();
        final restored = OAuthToken.fromJson(json);

        expect(restored.accessToken, original.accessToken);
        expect(restored.refreshToken, original.refreshToken);
        expect(restored.username, original.username);
        expect(restored.userId, original.userId);
        expect(restored.scopes, original.scopes);
      });

      test('roundtrip preserves data', () {
        final original = makeToken();
        final restored = OAuthToken.fromJson(original.toJson());

        expect(restored.accessToken, original.accessToken);
        expect(restored.refreshToken, original.refreshToken);
        expect(restored.username, original.username);
        expect(restored.userId, original.userId);
        expect(restored.scopes, original.scopes);
      });

      test('optional fields can be null', () {
        final token = OAuthToken(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: futureDate,
        );
        final json = token.toJson();

        expect(json.containsKey('username'), isFalse);
        expect(json.containsKey('user_id'), isFalse);

        final restored = OAuthToken.fromJson(json);
        expect(restored.username, isNull);
        expect(restored.userId, isNull);
      });
    });

    group('copyWith', () {
      test('copies with updated access token', () {
        final token = makeToken();
        final copy = token.copyWith(accessToken: 'new-access');

        expect(copy.accessToken, 'new-access');
        expect(copy.refreshToken, token.refreshToken);
        expect(copy.username, token.username);
      });

      test('preserves unchanged fields', () {
        final token = makeToken();
        final copy = token.copyWith();

        expect(copy.accessToken, token.accessToken);
        expect(copy.refreshToken, token.refreshToken);
        expect(copy.username, token.username);
        expect(copy.userId, token.userId);
        expect(copy.scopes, token.scopes);
      });
    });
  });
}
