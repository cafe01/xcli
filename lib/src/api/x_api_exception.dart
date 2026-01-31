import 'dart:convert';

/// Base exception for X API v2 errors.
///
/// Typed subclasses for common HTTP error codes:
/// - [AuthException] (401)
/// - [NotFoundException] (404)
/// - [RateLimitException] (429)
class XApiException implements Exception {
  /// Creates an API exception with [statusCode] and [message].
  const XApiException(this.statusCode, this.message, {this.detail});

  /// Parse an HTTP error response into a typed exception.
  ///
  /// Attempts to extract a meaningful message from the X API v2 error
  /// response JSON. Falls back to the raw body if parsing fails.
  factory XApiException.fromResponse(int statusCode, String body) {
    Map<String, dynamic>? json;
    String message;

    try {
      json = jsonDecode(body) as Map<String, dynamic>;
      final errors = json['errors'] as List<dynamic>?;
      final title = json['title'] as String?;
      final detailMsg = json['detail'] as String?;
      message = _extractMessage(errors, title, detailMsg) ??
          'HTTP $statusCode';
    } on FormatException {
      message = body.isNotEmpty ? body : 'HTTP $statusCode';
    }

    return switch (statusCode) {
      401 => AuthException(message, detail: json),
      404 => NotFoundException(message, detail: json),
      429 => RateLimitException(message, detail: json),
      _ => XApiException(statusCode, message, detail: json),
    };
  }

  /// HTTP status code.
  final int statusCode;

  /// Human-readable error message.
  final String message;

  /// Raw error response body (if parseable as JSON).
  final Map<String, dynamic>? detail;

  static String? _extractMessage(
    List<dynamic>? errors,
    String? title,
    String? detail,
  ) {
    if (errors != null && errors.isNotEmpty) {
      final first = errors.first as Map<String, dynamic>;
      return first['message'] as String?;
    }
    return title ?? detail;
  }

  @override
  String toString() => 'XApiException($statusCode): $message';
}

/// Authentication failure (401 Unauthorized).
class AuthException extends XApiException {
  /// Creates an auth exception.
  const AuthException(String message, {Map<String, dynamic>? detail})
      : super(401, message, detail: detail);
}

/// Resource not found (404 Not Found).
class NotFoundException extends XApiException {
  /// Creates a not-found exception.
  const NotFoundException(String message, {Map<String, dynamic>? detail})
      : super(404, message, detail: detail);
}

/// Rate limit exceeded (429 Too Many Requests).
class RateLimitException extends XApiException {
  /// Creates a rate-limit exception.
  const RateLimitException(String message, {Map<String, dynamic>? detail})
      : super(429, message, detail: detail);
}
