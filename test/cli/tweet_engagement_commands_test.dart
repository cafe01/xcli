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

  // ---------------------------------------------------------------
  // tweet like
  // ---------------------------------------------------------------
  group('tweet like', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.likeTweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'like', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Liked tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.likeTweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'like', '99']);

      verify(() => mockApi.likeTweet('99')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'like']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.likeTweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'like', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.likeTweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'like', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // tweet unlike
  // ---------------------------------------------------------------
  group('tweet unlike', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.unlikeTweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'unlike', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Unliked tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.unlikeTweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'unlike', '88']);

      verify(() => mockApi.unlikeTweet('88')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'unlike']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.unlikeTweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'unlike', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.unlikeTweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'unlike', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // tweet retweet
  // ---------------------------------------------------------------
  group('tweet retweet', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.retweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'retweet', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Retweeted tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.retweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'retweet', '77']);

      verify(() => mockApi.retweet('77')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'retweet']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.retweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'retweet', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.retweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'retweet', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // tweet unretweet
  // ---------------------------------------------------------------
  group('tweet unretweet', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.unretweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'unretweet', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Unretweeted tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.unretweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'unretweet', '66']);

      verify(() => mockApi.unretweet('66')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'unretweet']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.unretweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'unretweet', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.unretweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'unretweet', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // tweet bookmark
  // ---------------------------------------------------------------
  group('tweet bookmark', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.bookmarkTweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'bookmark', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Bookmarked tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.bookmarkTweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'bookmark', '55']);

      verify(() => mockApi.bookmarkTweet('55')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'bookmark']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.bookmarkTweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'bookmark', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.bookmarkTweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'bookmark', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // tweet unbookmark
  // ---------------------------------------------------------------
  group('tweet unbookmark', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.unbookmarkTweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'unbookmark', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Unbookmarked tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.unbookmarkTweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'unbookmark', '44']);

      verify(() => mockApi.unbookmarkTweet('44')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'unbookmark']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.unbookmarkTweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'unbookmark', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.unbookmarkTweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'unbookmark', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
