import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:xcli/src/auth/pkce.dart';

void main() {
  group('Pkce', () {
    group('generateCodeVerifier', () {
      test('produces string of default length 128', () {
        final verifier = Pkce.generateCodeVerifier();
        expect(verifier.length, 128);
      });

      test('produces string of custom length', () {
        final verifier = Pkce.generateCodeVerifier(64);
        expect(verifier.length, 64);
      });

      test('uses only unreserved characters (RFC 7636)', () {
        final verifier = Pkce.generateCodeVerifier();
        final unreserved = RegExp(r'^[A-Za-z0-9\-._~]+$');
        expect(unreserved.hasMatch(verifier), isTrue);
      });

      test('generates different values each call', () {
        final a = Pkce.generateCodeVerifier();
        final b = Pkce.generateCodeVerifier();
        expect(a, isNot(equals(b)));
      });

      test('minimum length is 43 per RFC 7636', () {
        final verifier = Pkce.generateCodeVerifier(43);
        expect(verifier.length, 43);
      });
    });

    group('generateCodeChallenge', () {
      test('produces base64url-encoded SHA256 without padding', () {
        final challenge = Pkce.generateCodeChallenge('test-verifier');
        // Must not contain padding characters
        expect(challenge, isNot(contains('=')));
        // Must be valid base64url characters
        final base64UrlChars = RegExp(r'^[A-Za-z0-9\-_]+$');
        expect(base64UrlChars.hasMatch(challenge), isTrue);
      });

      test('produces correct SHA256 for known input', () {
        // Manually verify: SHA256('hello') base64url without padding
        const input = 'hello';
        final expectedDigest = sha256.convert(utf8.encode(input));
        final expected = base64Url.encode(expectedDigest.bytes).replaceAll(
          '=',
          '',
        );

        final challenge = Pkce.generateCodeChallenge(input);
        expect(challenge, expected);
      });

      test('same input produces same challenge', () {
        final a = Pkce.generateCodeChallenge('deterministic-input');
        final b = Pkce.generateCodeChallenge('deterministic-input');
        expect(a, equals(b));
      });

      test('different inputs produce different challenges', () {
        final a = Pkce.generateCodeChallenge('input-a');
        final b = Pkce.generateCodeChallenge('input-b');
        expect(a, isNot(equals(b)));
      });

      test('challenge length is consistent (43 chars for SHA256)', () {
        // SHA256 = 32 bytes -> base64url = 43 chars (without padding)
        final challenge = Pkce.generateCodeChallenge('any-verifier');
        expect(challenge.length, 43);
      });
    });
  });
}
