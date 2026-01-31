import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE (Proof Key for Code Exchange) utilities for OAuth 2.0.
///
/// Generates code verifier and code challenge pairs per RFC 7636.
class Pkce {
  Pkce._();

  /// Characters allowed in code verifier (RFC 7636 Section 4.1).
  static const _unreserved =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// Generate a cryptographically random code verifier.
  ///
  /// Length defaults to 128 characters (maximum per RFC 7636).
  /// Minimum is 43 characters per spec.
  static String generateCodeVerifier([int length = 128]) {
    assert(length >= 43 && length <= 128, 'Length must be 43-128 per RFC 7636');
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _unreserved[random.nextInt(_unreserved.length)],
    ).join();
  }

  /// Generate a code challenge from a code verifier using S256 method.
  ///
  /// Returns base64url-encoded SHA256 hash without padding (per RFC 7636).
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
