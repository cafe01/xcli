import 'tweet.dart';

/// Minimal timeline response wrapper.
///
/// Wraps a list of tweets with pagination metadata from the X API v2
/// response envelope.
class TimelineResponse {
  const TimelineResponse({
    required this.tweets,
    this.nextToken,
    this.resultCount,
  });

  /// Parse from X API v2 timeline response.
  factory TimelineResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>?;

    return TimelineResponse(
      tweets: data
          .cast<Map<String, dynamic>>()
          .map(Tweet.fromJson)
          .toList(growable: false),
      nextToken: meta?['next_token'] as String?,
      resultCount: meta?['result_count'] as int?,
    );
  }

  final List<Tweet> tweets;
  final String? nextToken;
  final int? resultCount;
}
