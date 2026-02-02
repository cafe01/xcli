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

  /// Helper: a timeline response with multiple tweets.
  Map<String, dynamic> timelineResponse({
    List<Map<String, dynamic>>? tweets,
  }) {
    tweets ??= [
      <String, dynamic>{
        'id': '100',
        'text': 'First tweet',
        'author_id': '10',
      },
      <String, dynamic>{
        'id': '101',
        'text': 'Second tweet',
        'author_id': '11',
      },
      <String, dynamic>{
        'id': '102',
        'text': 'Third tweet',
        'author_id': '12',
      },
    ];
    return <String, dynamic>{'data': tweets};
  }

  /// Helper: empty timeline response.
  Map<String, dynamic> emptyResponse() =>
      <String, dynamic>{'data': <dynamic>[]};

  /// Helper: null data response.
  Map<String, dynamic> nullDataResponse() =>
      <String, dynamic>{'data': null};

  // ---------------------------------------------------------------
  // timeline home
  // ---------------------------------------------------------------
  group('timeline home', () {
    void stubHomeTimeline(Map<String, dynamic> response) {
      when(() => mockApi.homeTimeline(
            paginationToken: any(named: 'paginationToken'),
          )).thenAnswer((_) async => response);
    }

    test('displays human-readable output with multiple tweets', () async {
      stubHomeTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'home']);

      expect(result.code, 0);
      expect(result.output, contains('[100]'));
      expect(result.output, contains('First tweet'));
      expect(result.output, contains('[101]'));
      expect(result.output, contains('Second tweet'));
      expect(result.output, contains('[102]'));
      expect(result.output, contains('Third tweet'));
    });

    test('separates tweets with dividers', () async {
      stubHomeTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'home']);

      expect(result.code, 0);
      expect(result.output, contains('---'));
    });

    test('displays empty message when no tweets', () async {
      stubHomeTimeline(emptyResponse());

      final result =
          await runCapturing(runner, ['timeline', 'home']);

      expect(result.code, 0);
      expect(result.output, contains('No tweets found.'));
    });

    test('displays empty message when data is null', () async {
      stubHomeTimeline(nullDataResponse());

      final result =
          await runCapturing(runner, ['timeline', 'home']);

      expect(result.code, 0);
      expect(result.output, contains('No tweets found.'));
    });

    test('displays JSON output with --json flag', () async {
      stubHomeTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'home', '--json']);

      expect(result.code, 0);
      // Should be valid JSON
      final parsed = jsonDecode(result.output);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"First tweet"'));
    });

    test('--json output includes all tweets', () async {
      stubHomeTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'home', '--json']);

      expect(result.output, contains('"100"'));
      expect(result.output, contains('"101"'));
      expect(result.output, contains('"102"'));
    });

    test('displays single tweet correctly', () async {
      stubHomeTimeline(timelineResponse(tweets: [
        <String, dynamic>{
          'id': '200',
          'text': 'Only tweet',
          'author_id': '20',
        },
      ]));

      final result =
          await runCapturing(runner, ['timeline', 'home']);

      expect(result.code, 0);
      expect(result.output, contains('[200]'));
      expect(result.output, contains('Only tweet'));
      // Single tweet should not have dividers
      expect(result.output, isNot(contains('---')));
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.homeTimeline(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const XApiException(500, 'Server error'));

      expect(
        () => runner.run(['timeline', 'home']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.homeTimeline(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['timeline', 'home']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('propagates auth exceptions', () async {
      when(() => mockApi.homeTimeline(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['timeline', 'home']),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // timeline mentions
  // ---------------------------------------------------------------
  group('timeline mentions', () {
    void stubMentions(Map<String, dynamic> response) {
      when(() => mockApi.mentions(
            paginationToken: any(named: 'paginationToken'),
          )).thenAnswer((_) async => response);
    }

    test('displays human-readable output with multiple tweets', () async {
      stubMentions(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'mentions']);

      expect(result.code, 0);
      expect(result.output, contains('[100]'));
      expect(result.output, contains('First tweet'));
      expect(result.output, contains('[101]'));
      expect(result.output, contains('Second tweet'));
    });

    test('separates tweets with dividers', () async {
      stubMentions(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'mentions']);

      expect(result.code, 0);
      expect(result.output, contains('---'));
    });

    test('displays empty message when no mentions', () async {
      stubMentions(emptyResponse());

      final result =
          await runCapturing(runner, ['timeline', 'mentions']);

      expect(result.code, 0);
      expect(result.output, contains('No mentions found.'));
    });

    test('displays empty message when data is null', () async {
      stubMentions(nullDataResponse());

      final result =
          await runCapturing(runner, ['timeline', 'mentions']);

      expect(result.code, 0);
      expect(result.output, contains('No mentions found.'));
    });

    test('displays JSON output with --json flag', () async {
      stubMentions(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'mentions', '--json']);

      expect(result.code, 0);
      final parsed = jsonDecode(result.output);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"First tweet"'));
    });

    test('--json output includes all tweets', () async {
      stubMentions(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'mentions', '--json']);

      expect(result.output, contains('"100"'));
      expect(result.output, contains('"101"'));
      expect(result.output, contains('"102"'));
    });

    test('displays single mention correctly', () async {
      stubMentions(timelineResponse(tweets: [
        <String, dynamic>{
          'id': '300',
          'text': '@me hello there',
          'author_id': '30',
        },
      ]));

      final result =
          await runCapturing(runner, ['timeline', 'mentions']);

      expect(result.code, 0);
      expect(result.output, contains('[300]'));
      expect(result.output, contains('@me hello there'));
      expect(result.output, isNot(contains('---')));
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.mentions(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const XApiException(500, 'Server error'));

      expect(
        () => runner.run(['timeline', 'mentions']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.mentions(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['timeline', 'mentions']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('propagates auth exceptions', () async {
      when(() => mockApi.mentions(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['timeline', 'mentions']),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
