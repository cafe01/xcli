/// Abstract interface for X.com API v2 operations.
///
/// Defines the contract for all X.com API interactions. Commands depend on
/// this interface, never on a concrete implementation.
///
/// Concrete implementations (future):
/// - `RawHttpXApi` — direct HTTP via `package:http`
/// - `DartLibXApi` — pub.dev library wrapper, if a suitable one exists
/// - `XcurlXApi` — xurl CLI wrapper
abstract class XApi {
  // -- Tweet operations --

  /// Retrieve a single tweet by ID.
  Future<Map<String, dynamic>> getTweet(
    String id, {
    List<String>? expansions,
    List<String>? tweetFields,
    List<String>? userFields,
  });

  /// Create a new tweet.
  Future<Map<String, dynamic>> createTweet(
    String text, {
    String? replyToId,
    String? quoteTweetId,
  });

  /// Delete a tweet by ID.
  Future<void> deleteTweet(String id);

  /// Like a tweet.
  Future<void> likeTweet(String tweetId);

  /// Unlike a tweet.
  Future<void> unlikeTweet(String tweetId);

  /// Retweet a tweet.
  Future<void> retweet(String tweetId);

  /// Undo a retweet.
  Future<void> unretweet(String tweetId);

  /// Bookmark a tweet.
  Future<void> bookmarkTweet(String tweetId);

  /// Remove a bookmark.
  Future<void> unbookmarkTweet(String tweetId);

  /// List bookmarked tweets.
  Future<Map<String, dynamic>> getBookmarks({String? paginationToken});

  // -- Timeline operations --

  /// Retrieve the authenticated user's home timeline.
  Future<Map<String, dynamic>> homeTimeline({String? paginationToken});

  /// Retrieve a user's tweet timeline.
  Future<Map<String, dynamic>> userTimeline(
    String userId, {
    String? paginationToken,
  });

  /// Retrieve mentions of the authenticated user.
  Future<Map<String, dynamic>> mentions({String? paginationToken});

  // -- Search operations --

  /// Search recent tweets matching a query.
  Future<Map<String, dynamic>> searchTweets(
    String query, {
    String? paginationToken,
  });

  /// Search users by query (username lookup).
  Future<Map<String, dynamic>> searchUsers(String query);

  // -- User operations --

  /// Get a user profile by username.
  Future<Map<String, dynamic>> getUser(String username);

  /// Get the authenticated user's profile.
  Future<Map<String, dynamic>> getMe();

  /// Follow a user.
  Future<void> follow(String userId);

  /// Unfollow a user.
  Future<void> unfollow(String userId);

  /// Get followers of a user.
  Future<Map<String, dynamic>> getFollowers(
    String userId, {
    String? paginationToken,
  });

  /// Get users followed by a user.
  Future<Map<String, dynamic>> getFollowing(
    String userId, {
    String? paginationToken,
  });

  /// Block a user.
  Future<void> blockUser(String userId);

  /// Mute a user.
  Future<void> muteUser(String userId);

  // -- Raw escape hatch --

  /// Make an arbitrary X API v2 request.
  Future<Map<String, dynamic>> rawRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  });
}
