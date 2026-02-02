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

  /// Helper: stub getUser to resolve username to user ID.
  void stubGetUser(String username, String userId) {
    when(() => mockApi.getUser(username)).thenAnswer((_) async =>
        <String, dynamic>{
          'data': <String, dynamic>{
            'id': userId,
            'username': username,
            'name': 'Test User',
          },
        });
  }

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

  void stubUserTimeline(Map<String, dynamic> response) {
    when(() => mockApi.userTimeline(
          any(),
          paginationToken: any(named: 'paginationToken'),
        )).thenAnswer((_) async => response);
  }

  group('timeline user', () {
    test('resolves username and displays tweets', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('[100]'));
      expect(result.output, contains('First tweet'));
      expect(result.output, contains('[101]'));
      expect(result.output, contains('Second tweet'));
      expect(result.output, contains('[102]'));
      expect(result.output, contains('Third tweet'));
      verify(() => mockApi.getUser('alice')).called(1);
      verify(() => mockApi.userTimeline('50',
          paginationToken: any(named: 'paginationToken'))).called(1);
    });

    test('separates tweets with dividers', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('---'));
    });

    test('displays empty message when no tweets', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(emptyResponse());

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('No tweets found.'));
    });

    test('displays empty message when data is null', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(nullDataResponse());

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('No tweets found.'));
    });

    test('displays JSON output with --json flag', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice', '--json']);

      expect(result.code, 0);
      // Should be valid JSON
      final parsed = jsonDecode(result.output);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"First tweet"'));
    });

    test('--json output includes all tweets', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(timelineResponse());

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice', '--json']);

      expect(result.output, contains('"100"'));
      expect(result.output, contains('"101"'));
      expect(result.output, contains('"102"'));
    });

    test('displays single tweet correctly', () async {
      stubGetUser('alice', '50');
      stubUserTimeline(timelineResponse(tweets: [
        <String, dynamic>{
          'id': '200',
          'text': 'Only tweet',
          'author_id': '20',
        },
      ]));

      final result =
          await runCapturing(runner, ['timeline', 'user', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('[200]'));
      expect(result.output, contains('Only tweet'));
      // Single tweet should not have dividers
      expect(result.output, isNot(contains('---')));
    });

    test('exits 64 when no username argument provided', () async {
      final result =
          await runCapturing(runner, ['timeline', 'user']);

      expect(result.code, 64);
    });

    test('propagates API exceptions from getUser', () async {
      when(() => mockApi.getUser(any()))
          .thenThrow(const NotFoundException('User not found'));

      expect(
        () => runner.run(['timeline', 'user', 'nonexistent']),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('propagates API exceptions from userTimeline', () async {
      stubGetUser('alice', '50');
      when(() => mockApi.userTimeline(
            any(),
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const XApiException(500, 'Server error'));

      expect(
        () => runner.run(['timeline', 'user', 'alice']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      stubGetUser('alice', '50');
      when(() => mockApi.userTimeline(
            any(),
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['timeline', 'user', 'alice']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('propagates auth exceptions', () async {
      stubGetUser('alice', '50');
      when(() => mockApi.userTimeline(
            any(),
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['timeline', 'user', 'alice']),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
