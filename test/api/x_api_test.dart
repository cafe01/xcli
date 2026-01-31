import 'package:test/test.dart';
import 'package:xcli/src/api/x_api.dart';

/// Mock implementation to verify the XApi interface can be implemented.
class MockXApi implements XApi {
  @override
  Future<Map<String, dynamic>> getTweet(
    String id, {
    List<String>? expansions,
    List<String>? tweetFields,
    List<String>? userFields,
  }) async =>
      <String, dynamic>{'data': <String, dynamic>{}};

  @override
  Future<Map<String, dynamic>> createTweet(
    String text, {
    String? replyToId,
    String? quoteTweetId,
  }) async =>
      <String, dynamic>{'data': <String, dynamic>{}};

  @override
  Future<void> deleteTweet(String id) async {}

  @override
  Future<void> likeTweet(String tweetId) async {}

  @override
  Future<void> unlikeTweet(String tweetId) async {}

  @override
  Future<void> retweet(String tweetId) async {}

  @override
  Future<void> unretweet(String tweetId) async {}

  @override
  Future<void> bookmarkTweet(String tweetId) async {}

  @override
  Future<void> unbookmarkTweet(String tweetId) async {}

  @override
  Future<Map<String, dynamic>> getBookmarks({
    String? paginationToken,
  }) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> homeTimeline({
    String? paginationToken,
  }) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> userTimeline(
    String userId, {
    String? paginationToken,
  }) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> mentions({String? paginationToken}) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> searchTweets(
    String query, {
    String? paginationToken,
  }) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> searchUsers(String query) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> getUser(String username) async =>
      <String, dynamic>{'data': <String, dynamic>{}};

  @override
  Future<Map<String, dynamic>> getMe() async =>
      <String, dynamic>{'data': <String, dynamic>{}};

  @override
  Future<void> follow(String userId) async {}

  @override
  Future<void> unfollow(String userId) async {}

  @override
  Future<Map<String, dynamic>> getFollowers(
    String userId, {
    String? paginationToken,
  }) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> getFollowing(
    String userId, {
    String? paginationToken,
  }) async =>
      <String, dynamic>{'data': <dynamic>[]};

  @override
  Future<void> blockUser(String userId) async {}

  @override
  Future<void> muteUser(String userId) async {}

  @override
  Future<Map<String, dynamic>> rawRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async =>
      <String, dynamic>{'data': <String, dynamic>{}};
}

void main() {
  group('XApi interface', () {
    test('can be implemented', () {
      final api = MockXApi();
      expect(api, isA<XApi>());
    });

    test('getTweet returns response map', () async {
      final api = MockXApi();
      final result = await api.getTweet('123');
      expect(result, containsPair('data', isA<Map<String, dynamic>>()));
    });

    test('createTweet returns response map', () async {
      final api = MockXApi();
      final result = await api.createTweet('Hello world');
      expect(result, containsPair('data', isA<Map<String, dynamic>>()));
    });

    test('homeTimeline returns response map', () async {
      final api = MockXApi();
      final result = await api.homeTimeline();
      expect(result, containsPair('data', isA<List<dynamic>>()));
    });

    test('searchTweets returns response map', () async {
      final api = MockXApi();
      final result = await api.searchTweets('dart');
      expect(result, containsPair('data', isA<List<dynamic>>()));
    });

    test('getUser returns response map', () async {
      final api = MockXApi();
      final result = await api.getUser('bentos');
      expect(result, containsPair('data', isA<Map<String, dynamic>>()));
    });

    test('rawRequest returns response map', () async {
      final api = MockXApi();
      final result = await api.rawRequest('GET', '/2/tweets/123');
      expect(result, containsPair('data', isA<Map<String, dynamic>>()));
    });

    test('void operations complete without error', () async {
      final api = MockXApi();
      await api.likeTweet('123');
      await api.unlikeTweet('123');
      await api.retweet('123');
      await api.unretweet('123');
      await api.bookmarkTweet('123');
      await api.unbookmarkTweet('123');
      await api.follow('456');
      await api.unfollow('456');
      await api.blockUser('456');
      await api.muteUser('456');
      await api.deleteTweet('123');
    });
  });
}
