import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:xcli/src/api/x_api.dart';
import 'package:xcli/src/api/x_api_exception.dart';
import 'package:xcli/src/cli/x_runner.dart';

class MockXApi extends Mock implements XApi {}

/// Run a command and capture all print output.
Future<({int? code, String output})> runCapturing(
  XCommandRunner runner,
  List<String> args,
) async {
  final lines = <String>[];
  final code = await runZonedGuarded(
    () => runner.run(args),
    (_, _) {},
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        lines.add(line);
      },
    ),
  );
  return (code: code, output: lines.join('\n'));
}

void main() {
  late MockXApi mockApi;
  late XCommandRunner runner;

  setUp(() {
    mockApi = MockXApi();
    runner = XCommandRunner(api: mockApi);
  });

  /// Full API response for a tweet with author expansion.
  Map<String, dynamic> tweetResponse({
    String id = '123',
    String text = 'Hello world',
    String authorId = '999',
    String authorName = 'Test User',
    String authorUsername = 'testuser',
    int likes = 42,
    int retweets = 7,
    int replies = 3,
  }) =>
      <String, dynamic>{
        'data': <String, dynamic>{
          'id': id,
          'text': text,
          'author_id': authorId,
          'created_at': '2026-01-31T12:00:00.000Z',
          'public_metrics': <String, dynamic>{
            'like_count': likes,
            'retweet_count': retweets,
            'reply_count': replies,
          },
        },
        'includes': <String, dynamic>{
          'users': <dynamic>[
            <String, dynamic>{
              'id': authorId,
              'name': authorName,
              'username': authorUsername,
            },
          ],
        },
      };

  void stubGetTweet(Map<String, dynamic> response) {
    when(() => mockApi.getTweet(
          any(),
          expansions: any(named: 'expansions'),
          tweetFields: any(named: 'tweetFields'),
          userFields: any(named: 'userFields'),
        )).thenAnswer((_) async => response);
  }

  group('tweet view', () {
    test('displays human-readable output by default', () async {
      stubGetTweet(tweetResponse());

      final result = await runCapturing(runner, ['tweet', 'view', '123']);

      expect(result.code, 0);
      expect(result.output, contains('@testuser'));
      expect(result.output, contains('Test User'));
      expect(result.output, contains('Hello world'));
      expect(result.output, contains('42 Likes'));
      expect(result.output, contains('7 Retweets'));
      expect(result.output, contains('3 Replies'));
    });

    test('displays JSON output with --json flag', () async {
      stubGetTweet(tweetResponse(text: 'JSON test'));

      final result =
          await runCapturing(runner, ['tweet', 'view', '--json', '123']);

      expect(result.code, 0);
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"JSON test"'));
    });

    test('requests correct expansions and fields', () async {
      stubGetTweet(tweetResponse());

      await runCapturing(runner, ['tweet', 'view', '123']);

      final captured = verify(() => mockApi.getTweet(
            captureAny(),
            expansions: captureAny(named: 'expansions'),
            tweetFields: captureAny(named: 'tweetFields'),
            userFields: captureAny(named: 'userFields'),
          )).captured;

      expect(captured[0], '123');
      expect(captured[1], contains('author_id'));
      expect(captured[2], contains('public_metrics'));
      expect(captured[3], contains('username'));
    });

    test('handles missing includes gracefully', () async {
      stubGetTweet(<String, dynamic>{
        'data': <String, dynamic>{
          'id': '123',
          'text': 'No author info',
        },
      });

      final result = await runCapturing(runner, ['tweet', 'view', '123']);

      expect(result.code, 0);
      expect(result.output, contains('@unknown'));
      expect(result.output, contains('No author info'));
    });

    test('handles null data (tweet not found)', () async {
      stubGetTweet(<String, dynamic>{'data': null});

      final result = await runCapturing(runner, ['tweet', 'view', '123']);

      expect(result.code, 0);
      expect(result.output, contains('Tweet not found'));
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'view']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.getTweet(
            any(),
            expansions: any(named: 'expansions'),
            tweetFields: any(named: 'tweetFields'),
            userFields: any(named: 'userFields'),
          )).thenThrow(const NotFoundException('Tweet not found'));

      expect(
        () => runner.run(['tweet', 'view', '999']),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
