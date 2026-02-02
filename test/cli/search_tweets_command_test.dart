import 'dart:async';
import 'dart:convert';

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

  /// Helper: search response with tweet results.
  Map<String, dynamic> searchResponse({
    List<Map<String, dynamic>>? tweets,
  }) {
    tweets ??= [
      <String, dynamic>{
        'id': '500',
        'text': 'Matching tweet one',
        'author_id': '50',
      },
      <String, dynamic>{
        'id': '501',
        'text': 'Matching tweet two',
        'author_id': '51',
      },
    ];
    return <String, dynamic>{'data': tweets};
  }

  /// Helper: empty search response.
  Map<String, dynamic> emptyResponse() =>
      <String, dynamic>{'data': <dynamic>[]};

  /// Helper: null data response.
  Map<String, dynamic> nullDataResponse() =>
      <String, dynamic>{'data': null};

  void stubSearchTweets(Map<String, dynamic> response) {
    when(() => mockApi.searchTweets(
          any(),
          paginationToken: any(named: 'paginationToken'),
        )).thenAnswer((_) async => response);
  }

  group('search tweets', () {
    test('displays human-readable results', () async {
      stubSearchTweets(searchResponse());

      final result =
          await runCapturing(runner, ['search', 'tweets', 'dart lang']);

      expect(result.code, 0);
      expect(result.output, contains('[500]'));
      expect(result.output, contains('Matching tweet one'));
      expect(result.output, contains('[501]'));
      expect(result.output, contains('Matching tweet two'));
    });

    test('separates results with dividers', () async {
      stubSearchTweets(searchResponse());

      final result =
          await runCapturing(runner, ['search', 'tweets', 'test']);

      expect(result.code, 0);
      expect(result.output, contains('---'));
    });

    test('joins multiple words as query', () async {
      stubSearchTweets(searchResponse());

      await runCapturing(
          runner, ['search', 'tweets', 'flutter', 'dart', 'sdk']);

      final captured = verify(() => mockApi.searchTweets(
            captureAny(),
            paginationToken: any(named: 'paginationToken'),
          )).captured;

      expect(captured[0], 'flutter dart sdk');
    });

    test('displays empty message when no results', () async {
      stubSearchTweets(emptyResponse());

      final result =
          await runCapturing(runner, ['search', 'tweets', 'nonexistent']);

      expect(result.code, 0);
      expect(result.output, contains('No tweets found.'));
    });

    test('displays empty message when data is null', () async {
      stubSearchTweets(nullDataResponse());

      final result =
          await runCapturing(runner, ['search', 'tweets', 'nothing']);

      expect(result.code, 0);
      expect(result.output, contains('No tweets found.'));
    });

    test('displays JSON output with --json flag', () async {
      stubSearchTweets(searchResponse());

      final result = await runCapturing(
          runner, ['search', 'tweets', '--json', 'dart lang']);

      expect(result.code, 0);
      final parsed = jsonDecode(result.output);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"Matching tweet one"'));
    });

    test('--json output includes all results', () async {
      stubSearchTweets(searchResponse());

      final result = await runCapturing(
          runner, ['search', 'tweets', '--json', 'test']);

      expect(result.output, contains('"500"'));
      expect(result.output, contains('"501"'));
    });

    test('displays single result correctly', () async {
      stubSearchTweets(searchResponse(tweets: [
        <String, dynamic>{
          'id': '600',
          'text': 'Solo result',
          'author_id': '60',
        },
      ]));

      final result =
          await runCapturing(runner, ['search', 'tweets', 'solo']);

      expect(result.code, 0);
      expect(result.output, contains('[600]'));
      expect(result.output, contains('Solo result'));
      expect(result.output, isNot(contains('---')));
    });

    test('exits 64 when no query argument provided', () async {
      final result = await runCapturing(runner, ['search', 'tweets']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.searchTweets(
            any(),
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const XApiException(500, 'Server error'));

      expect(
        () => runner.run(['search', 'tweets', 'test']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.searchTweets(
            any(),
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['search', 'tweets', 'test']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('propagates auth exceptions', () async {
      when(() => mockApi.searchTweets(
            any(),
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['search', 'tweets', 'test']),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
