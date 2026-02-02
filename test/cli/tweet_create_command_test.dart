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

  /// API response for a created tweet.
  Map<String, dynamic> createResponse({
    String id = '456',
    String text = 'Hello world',
  }) =>
      <String, dynamic>{
        'data': <String, dynamic>{
          'id': id,
          'text': text,
        },
      };

  void stubCreateTweet(Map<String, dynamic> response) {
    when(() => mockApi.createTweet(
          any(),
          replyToId: any(named: 'replyToId'),
          quoteTweetId: any(named: 'quoteTweetId'),
        )).thenAnswer((_) async => response);
  }

  group('tweet create', () {
    test('displays confirmation by default', () async {
      stubCreateTweet(createResponse());

      final result =
          await runCapturing(runner, ['tweet', 'create', 'Hello world']);

      expect(result.code, 0);
      expect(result.output, contains('Tweet posted!'));
      expect(result.output, contains('Hello world'));
      expect(result.output, contains('ID: 456'));
      expect(result.output, contains('https://x.com/i/status/456'));
    });

    test('displays JSON output with --json flag', () async {
      stubCreateTweet(createResponse(text: 'JSON test'));

      final result = await runCapturing(
          runner, ['tweet', 'create', '--json', 'JSON test']);

      expect(result.code, 0);
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"JSON test"'));
    });

    test('joins multiple words as tweet text', () async {
      stubCreateTweet(createResponse(text: 'Hello beautiful world'));

      await runCapturing(
          runner, ['tweet', 'create', 'Hello', 'beautiful', 'world']);

      final captured = verify(() => mockApi.createTweet(
            captureAny(),
            replyToId: any(named: 'replyToId'),
            quoteTweetId: any(named: 'quoteTweetId'),
          )).captured;

      expect(captured[0], 'Hello beautiful world');
    });

    test('passes --reply-to flag to API', () async {
      stubCreateTweet(createResponse());

      await runCapturing(
          runner, ['tweet', 'create', '--reply-to', '789', 'My reply']);

      final captured = verify(() => mockApi.createTweet(
            captureAny(),
            replyToId: captureAny(named: 'replyToId'),
            quoteTweetId: any(named: 'quoteTweetId'),
          )).captured;

      expect(captured[0], 'My reply');
      expect(captured[1], '789');
    });

    test('passes --quote flag to API', () async {
      stubCreateTweet(createResponse());

      await runCapturing(
          runner, ['tweet', 'create', '--quote', '111', 'Quote this']);

      final captured = verify(() => mockApi.createTweet(
            captureAny(),
            replyToId: any(named: 'replyToId'),
            quoteTweetId: captureAny(named: 'quoteTweetId'),
          )).captured;

      expect(captured[0], 'Quote this');
      expect(captured[1], '111');
    });

    test('passes both --reply-to and --quote flags', () async {
      stubCreateTweet(createResponse());

      await runCapturing(runner,
          ['tweet', 'create', '--reply-to', '789', '--quote', '111', 'Both']);

      final captured = verify(() => mockApi.createTweet(
            captureAny(),
            replyToId: captureAny(named: 'replyToId'),
            quoteTweetId: captureAny(named: 'quoteTweetId'),
          )).captured;

      expect(captured[0], 'Both');
      expect(captured[1], '789');
      expect(captured[2], '111');
    });

    test('handles null data in response', () async {
      stubCreateTweet(<String, dynamic>{'data': null});

      final result =
          await runCapturing(runner, ['tweet', 'create', 'test']);

      expect(result.code, 0);
      expect(result.output, contains('Failed to create tweet'));
    });

    test('exits 64 when no text argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'create']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.createTweet(
            any(),
            replyToId: any(named: 'replyToId'),
            quoteTweetId: any(named: 'quoteTweetId'),
          )).thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'create', 'test']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.createTweet(
            any(),
            replyToId: any(named: 'replyToId'),
            quoteTweetId: any(named: 'quoteTweetId'),
          )).thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'create', 'test']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('includes tweet URL in confirmation', () async {
      stubCreateTweet(createResponse(id: '99887766'));

      final result =
          await runCapturing(runner, ['tweet', 'create', 'test post']);

      expect(result.output, contains('https://x.com/i/status/99887766'));
    });

    test('--json flag with --reply-to returns full response', () async {
      final resp = createResponse(text: 'reply text');
      stubCreateTweet(resp);

      final result = await runCapturing(
          runner, ['tweet', 'create', '--json', '--reply-to', '789', 'reply text']);

      expect(result.code, 0);
      expect(result.output, contains('"id"'));
      expect(result.output, contains('"reply text"'));
    });
  });
}
