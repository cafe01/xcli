import 'dart:convert';

import 'package:http/http.dart' as http;

import 'x_api.dart';
import 'x_api_exception.dart';

/// Concrete [XApi] implementation using raw HTTP via `package:http`.
///
/// Takes any [http.Client] as transport, allowing injection of
/// [AuthenticatedClient] for production or a mock for testing.
///
/// Priority methods (R4.0): getTweet, getUser, getMe, createTweet,
/// homeTimeline. All others throw [UnimplementedError] until wired.
class RawHttpXApi implements XApi {
  /// Creates an API client backed by [client].
  ///
  /// The [client] handles auth headers (when using [AuthenticatedClient])
  /// and can be a mock for testing.
  RawHttpXApi({required http.Client client}) : _client = client;

  final http.Client _client;

  /// X API v2 base URL.
  static const baseUrl = 'https://api.x.com/2';

  /// Cached authenticated user ID, resolved lazily via [getMe].
  String? _userId;

  // -- Implemented methods (R4.0) --

  @override
  Future<Map<String, dynamic>> getTweet(
    String id, {
    List<String>? expansions,
    List<String>? tweetFields,
    List<String>? userFields,
  }) async {
    final params = <String, String>{};
    if (expansions != null && expansions.isNotEmpty) {
      params['expansions'] = expansions.join(',');
    }
    if (tweetFields != null && tweetFields.isNotEmpty) {
      params['tweet.fields'] = tweetFields.join(',');
    }
    if (userFields != null && userFields.isNotEmpty) {
      params['user.fields'] = userFields.join(',');
    }
    return _get('/tweets/$id', queryParams: params);
  }

  @override
  Future<Map<String, dynamic>> getUser(String username) async {
    return _get('/users/by/username/$username');
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    return _get('/users/me');
  }

  @override
  Future<Map<String, dynamic>> createTweet(
    String text, {
    String? replyToId,
    String? quoteTweetId,
  }) async {
    final body = <String, dynamic>{'text': text};
    if (replyToId != null) {
      body['reply'] = <String, dynamic>{'in_reply_to_tweet_id': replyToId};
    }
    if (quoteTweetId != null) {
      body['quote_tweet_id'] = quoteTweetId;
    }
    return _post('/tweets', body: body);
  }

  @override
  Future<Map<String, dynamic>> homeTimeline({
    String? paginationToken,
  }) async {
    final userId = await _resolveUserId();
    final params = <String, String>{};
    if (paginationToken != null) {
      params['pagination_token'] = paginationToken;
    }
    return _get(
      '/users/$userId/timelines/reverse_chronological',
      queryParams: params,
    );
  }

  // -- Stubbed methods (future rounds) --

  @override
  Future<void> deleteTweet(String id) => _stub('deleteTweet');

  @override
  Future<void> likeTweet(String tweetId) => _stub('likeTweet');

  @override
  Future<void> unlikeTweet(String tweetId) => _stub('unlikeTweet');

  @override
  Future<void> retweet(String tweetId) => _stub('retweet');

  @override
  Future<void> unretweet(String tweetId) => _stub('unretweet');

  @override
  Future<void> bookmarkTweet(String tweetId) => _stub('bookmarkTweet');

  @override
  Future<void> unbookmarkTweet(String tweetId) => _stub('unbookmarkTweet');

  @override
  Future<Map<String, dynamic>> getBookmarks({String? paginationToken}) =>
      _stub('getBookmarks');

  @override
  Future<Map<String, dynamic>> userTimeline(
    String userId, {
    String? paginationToken,
  }) =>
      _stub('userTimeline');

  @override
  Future<Map<String, dynamic>> mentions({String? paginationToken}) =>
      _stub('mentions');

  @override
  Future<Map<String, dynamic>> searchTweets(
    String query, {
    String? paginationToken,
  }) =>
      _stub('searchTweets');

  @override
  Future<Map<String, dynamic>> searchUsers(String query) =>
      _stub('searchUsers');

  @override
  Future<void> follow(String userId) => _stub('follow');

  @override
  Future<void> unfollow(String userId) => _stub('unfollow');

  @override
  Future<Map<String, dynamic>> getFollowers(
    String userId, {
    String? paginationToken,
  }) =>
      _stub('getFollowers');

  @override
  Future<Map<String, dynamic>> getFollowing(
    String userId, {
    String? paginationToken,
  }) =>
      _stub('getFollowing');

  @override
  Future<void> blockUser(String userId) => _stub('blockUser');

  @override
  Future<void> muteUser(String userId) => _stub('muteUser');

  @override
  Future<Map<String, dynamic>> rawRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) =>
      _stub('rawRequest');

  // -- Private helpers --

  /// Resolve the authenticated user's ID, caching the result.
  Future<String> _resolveUserId() async {
    if (_userId != null) return _userId!;
    final me = await getMe();
    final data = me['data'] as Map<String, dynamic>;
    _userId = data['id'] as String;
    return _userId!;
  }

  /// HTTP GET with query parameters.
  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters:
          queryParams != null && queryParams.isNotEmpty ? queryParams : null,
    );
    final response = await _client.get(uri);
    return _handleResponse(response);
  }

  /// HTTP POST with JSON body.
  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Parse response or throw typed exception.
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw XApiException.fromResponse(response.statusCode, response.body);
  }

  /// Throw for unimplemented methods.
  Never _stub(String method) {
    throw UnimplementedError('RawHttpXApi.$method');
  }
}
