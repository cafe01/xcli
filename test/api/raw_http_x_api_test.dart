import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:xcli/src/api/raw_http_x_api.dart';
import 'package:xcli/src/api/x_api_exception.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late RawHttpXApi api;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    api = RawHttpXApi(client: mockClient);
  });

  // -- Helper to stub GET responses --

  void stubGet(String urlPattern, {int status = 200, Object? body}) {
    when(() => mockClient.get(
          any(that: predicate<Uri>((uri) => uri.toString().contains(urlPattern))),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          body is String ? body : jsonEncode(body ?? <String, dynamic>{}),
          status,
        ));
  }

  void stubPost(String urlPattern, {int status = 200, Object? body}) {
    when(() => mockClient.post(
          any(that: predicate<Uri>((uri) => uri.toString().contains(urlPattern))),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          encoding: any(named: 'encoding'),
        )).thenAnswer((_) async => http.Response(
          body is String ? body : jsonEncode(body ?? <String, dynamic>{}),
          status,
        ));
  }

  // ===== getTweet =====

  group('getTweet', () {
    test('calls GET /2/tweets/:id', () async {
      stubGet('/tweets/123', body: <String, dynamic>{
        'data': <String, dynamic>{
          'id': '123',
          'text': 'Hello world',
        },
      });

      final result = await api.getTweet('123');

      expect(result['data'], isA<Map<String, dynamic>>());
      expect((result['data'] as Map)['id'], '123');

      final captured = verify(() => mockClient.get(
            captureAny(),
            headers: any(named: 'headers'),
          )).captured.single as Uri;
      expect(captured.path, '/2/tweets/123');
    });

    test('passes expansions as query parameter', () async {
      stubGet('/tweets/456', body: <String, dynamic>{
        'data': <String, dynamic>{'id': '456', 'text': 'Test'},
      });

      await api.getTweet(
        '456',
        expansions: ['author_id'],
        tweetFields: ['created_at', 'public_metrics'],
        userFields: ['name', 'username'],
      );

      final captured = verify(() => mockClient.get(
            captureAny(),
            headers: any(named: 'headers'),
          )).captured.single as Uri;
      expect(captured.queryParameters['expansions'], 'author_id');
      expect(captured.queryParameters['tweet.fields'],
          'created_at,public_metrics');
      expect(captured.queryParameters['user.fields'], 'name,username');
    });

    test('omits empty expansion lists from query', () async {
      stubGet('/tweets/789', body: <String, dynamic>{
        'data': <String, dynamic>{'id': '789', 'text': 'Test'},
      });

      await api.getTweet('789');

      final captured = verify(() => mockClient.get(
            captureAny(),
            headers: any(named: 'headers'),
          )).captured.single as Uri;
      expect(captured.queryParameters, isEmpty);
    });

    test('throws NotFoundException on 404', () async {
      stubGet('/tweets/missing', status: 404, body: jsonEncode(<String, dynamic>{
        'errors': [
          <String, dynamic>{
            'message': 'Tweet not found',
            'resource_type': 'tweet',
          }
        ],
        'title': 'Not Found Error',
      }));

      expect(
        () => api.getTweet('missing'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('throws AuthException on 401', () async {
      stubGet('/tweets/secret', status: 401, body: jsonEncode(<String, dynamic>{
        'title': 'Unauthorized',
        'detail': 'Missing or invalid authentication.',
      }));

      expect(
        () => api.getTweet('secret'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws RateLimitException on 429', () async {
      stubGet('/tweets/spam', status: 429, body: jsonEncode(<String, dynamic>{
        'title': 'Too Many Requests',
        'detail': 'Rate limit exceeded.',
      }));

      expect(
        () => api.getTweet('spam'),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ===== getUser =====

  group('getUser', () {
    test('calls GET /2/users/by/username/:username', () async {
      stubGet('/users/by/username/alfred', body: <String, dynamic>{
        'data': <String, dynamic>{
          'id': '999',
          'name': 'Alfred',
          'username': 'alfred',
        },
      });

      final result = await api.getUser('alfred');
      expect((result['data'] as Map)['username'], 'alfred');

      final captured = verify(() => mockClient.get(
            captureAny(),
            headers: any(named: 'headers'),
          )).captured.single as Uri;
      expect(captured.path, '/2/users/by/username/alfred');
    });
  });

  // ===== getMe =====

  group('getMe', () {
    test('calls GET /2/users/me', () async {
      stubGet('/users/me', body: <String, dynamic>{
        'data': <String, dynamic>{
          'id': '42',
          'name': 'Test User',
          'username': 'testuser',
        },
      });

      final result = await api.getMe();
      expect((result['data'] as Map)['id'], '42');

      final captured = verify(() => mockClient.get(
            captureAny(),
            headers: any(named: 'headers'),
          )).captured.single as Uri;
      expect(captured.path, '/2/users/me');
    });
  });

  // ===== createTweet =====

  group('createTweet', () {
    test('posts to /2/tweets with text body', () async {
      stubPost('/tweets', body: <String, dynamic>{
        'data': <String, dynamic>{
          'id': '555',
          'text': 'Hello from xcli!',
        },
      });

      final result = await api.createTweet('Hello from xcli!');
      expect((result['data'] as Map)['text'], 'Hello from xcli!');

      final captured = verify(() => mockClient.post(
            captureAny(),
            headers: captureAny(named: 'headers'),
            body: captureAny(named: 'body'),
            encoding: any(named: 'encoding'),
          )).captured;
      final uri = captured[0] as Uri;
      final headers = captured[1] as Map<String, String>;
      final body = jsonDecode(captured[2] as String) as Map<String, dynamic>;

      expect(uri.path, '/2/tweets');
      expect(headers['Content-Type'], 'application/json');
      expect(body['text'], 'Hello from xcli!');
    });

    test('includes reply_to when replyToId is set', () async {
      stubPost('/tweets', body: <String, dynamic>{
        'data': <String, dynamic>{'id': '556', 'text': 'Reply'},
      });

      await api.createTweet('Reply', replyToId: '100');

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
            encoding: any(named: 'encoding'),
          )).captured;
      final body = jsonDecode(captured.single as String) as Map<String, dynamic>;
      expect(body['reply'], <String, dynamic>{'in_reply_to_tweet_id': '100'});
    });

    test('includes quote_tweet_id when set', () async {
      stubPost('/tweets', body: <String, dynamic>{
        'data': <String, dynamic>{'id': '557', 'text': 'Quote'},
      });

      await api.createTweet('Quote', quoteTweetId: '200');

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
            encoding: any(named: 'encoding'),
          )).captured;
      final body = jsonDecode(captured.single as String) as Map<String, dynamic>;
      expect(body['quote_tweet_id'], '200');
    });
  });

  // ===== homeTimeline =====

  group('homeTimeline', () {
    test('resolves userId via getMe then calls timeline endpoint', () async {
      // First call: getMe to resolve userId
      stubGet('/users/me', body: <String, dynamic>{
        'data': <String, dynamic>{
          'id': '42',
          'name': 'Test',
          'username': 'test',
        },
      });

      // Second call: the actual timeline
      stubGet('/timelines/reverse_chronological', body: <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'id': '1', 'text': 'First tweet'},
          <String, dynamic>{'id': '2', 'text': 'Second tweet'},
        ],
        'meta': <String, dynamic>{
          'result_count': 2,
          'next_token': 'abc123',
        },
      });

      final result = await api.homeTimeline();
      expect(result['data'], isA<List<dynamic>>());
      expect((result['data'] as List).length, 2);
    });

    test('caches userId after first resolution', () async {
      stubGet('/users/me', body: <String, dynamic>{
        'data': <String, dynamic>{'id': '42', 'name': 'T', 'username': 't'},
      });
      stubGet('/timelines/reverse_chronological', body: <String, dynamic>{
        'data': <dynamic>[],
      });

      await api.homeTimeline();
      await api.homeTimeline();

      // getMe should only be called once
      verify(() => mockClient.get(
            any(that: predicate<Uri>((u) => u.path == '/2/users/me')),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('passes pagination token', () async {
      stubGet('/users/me', body: <String, dynamic>{
        'data': <String, dynamic>{'id': '42', 'name': 'T', 'username': 't'},
      });
      stubGet('/timelines/reverse_chronological', body: <String, dynamic>{
        'data': <dynamic>[],
      });

      await api.homeTimeline(paginationToken: 'page2');

      final captured = verify(() => mockClient.get(
            captureAny(
                that: predicate<Uri>(
                    (u) => u.path.contains('reverse_chronological'))),
            headers: any(named: 'headers'),
          )).captured.single as Uri;
      expect(captured.queryParameters['pagination_token'], 'page2');
    });
  });

  // ===== Error handling =====

  group('XApiException.fromResponse', () {
    test('parses errors array', () {
      final ex = XApiException.fromResponse(
        400,
        jsonEncode(<String, dynamic>{
          'errors': [
            <String, dynamic>{'message': 'Invalid request'},
          ],
        }),
      );
      expect(ex.statusCode, 400);
      expect(ex.message, 'Invalid request');
    });

    test('falls back to title field', () {
      final ex = XApiException.fromResponse(
        403,
        jsonEncode(<String, dynamic>{'title': 'Forbidden'}),
      );
      expect(ex.message, 'Forbidden');
    });

    test('falls back to detail field', () {
      final ex = XApiException.fromResponse(
        500,
        jsonEncode(<String, dynamic>{'detail': 'Internal error'}),
      );
      expect(ex.message, 'Internal error');
    });

    test('handles non-JSON body', () {
      final ex = XApiException.fromResponse(502, 'Bad Gateway');
      expect(ex.message, 'Bad Gateway');
      expect(ex.detail, isNull);
    });

    test('handles empty body', () {
      final ex = XApiException.fromResponse(503, '');
      expect(ex.message, 'HTTP 503');
    });

    test('returns typed AuthException for 401', () {
      final ex = XApiException.fromResponse(
        401,
        jsonEncode(<String, dynamic>{'title': 'Unauthorized'}),
      );
      expect(ex, isA<AuthException>());
      expect(ex.statusCode, 401);
    });

    test('returns typed NotFoundException for 404', () {
      final ex = XApiException.fromResponse(
        404,
        jsonEncode(<String, dynamic>{'title': 'Not Found'}),
      );
      expect(ex, isA<NotFoundException>());
    });

    test('returns typed RateLimitException for 429', () {
      final ex = XApiException.fromResponse(
        429,
        jsonEncode(<String, dynamic>{'title': 'Too Many Requests'}),
      );
      expect(ex, isA<RateLimitException>());
    });
  });

  // ===== Stubs =====

  group('stubbed methods', () {
    test('throw UnimplementedError', () {
      expect(() => api.deleteTweet('1'), throwsUnimplementedError);
      expect(() => api.likeTweet('1'), throwsUnimplementedError);
      expect(() => api.unlikeTweet('1'), throwsUnimplementedError);
      expect(() => api.retweet('1'), throwsUnimplementedError);
      expect(() => api.unretweet('1'), throwsUnimplementedError);
      expect(() => api.bookmarkTweet('1'), throwsUnimplementedError);
      expect(() => api.unbookmarkTweet('1'), throwsUnimplementedError);
      expect(() => api.getBookmarks(), throwsUnimplementedError);
      expect(() => api.userTimeline('1'), throwsUnimplementedError);
      expect(() => api.mentions(), throwsUnimplementedError);
      expect(() => api.searchTweets('q'), throwsUnimplementedError);
      expect(() => api.searchUsers('q'), throwsUnimplementedError);
      expect(() => api.follow('1'), throwsUnimplementedError);
      expect(() => api.unfollow('1'), throwsUnimplementedError);
      expect(() => api.getFollowers('1'), throwsUnimplementedError);
      expect(() => api.getFollowing('1'), throwsUnimplementedError);
      expect(() => api.blockUser('1'), throwsUnimplementedError);
      expect(() => api.muteUser('1'), throwsUnimplementedError);
      expect(() => api.rawRequest('GET', '/2/test'), throwsUnimplementedError);
    });
  });
}
