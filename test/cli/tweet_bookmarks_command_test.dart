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

  /// Helper: a bookmarks response with multiple tweets.
  Map<String, dynamic> bookmarksResponse({
    List<Map<String, dynamic>>? tweets,
  }) {
    tweets ??= [
      <String, dynamic>{
        'id': '100',
        'text': 'First bookmark',
        'author_id': '10',
      },
      <String, dynamic>{
        'id': '101',
        'text': 'Second bookmark',
        'author_id': '11',
      },
      <String, dynamic>{
        'id': '102',
        'text': 'Third bookmark',
        'author_id': '12',
      },
    ];
    return <String, dynamic>{'data': tweets};
  }

  /// Helper: empty response.
  Map<String, dynamic> emptyResponse() =>
      <String, dynamic>{'data': <dynamic>[]};

  /// Helper: null data response.
  Map<String, dynamic> nullDataResponse() =>
      <String, dynamic>{'data': null};

  void stubGetBookmarks(Map<String, dynamic> response) {
    when(() => mockApi.getBookmarks(
          paginationToken: any(named: 'paginationToken'),
        )).thenAnswer((_) async => response);
  }

  group('tweet bookmarks', () {
    test('displays human-readable output with multiple bookmarks', () async {
      stubGetBookmarks(bookmarksResponse());

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks']);

      expect(result.code, 0);
      expect(result.output, contains('[100]'));
      expect(result.output, contains('First bookmark'));
      expect(result.output, contains('[101]'));
      expect(result.output, contains('Second bookmark'));
      expect(result.output, contains('[102]'));
      expect(result.output, contains('Third bookmark'));
    });

    test('separates bookmarks with dividers', () async {
      stubGetBookmarks(bookmarksResponse());

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks']);

      expect(result.code, 0);
      expect(result.output, contains('---'));
    });

    test('displays empty message when no bookmarks', () async {
      stubGetBookmarks(emptyResponse());

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks']);

      expect(result.code, 0);
      expect(result.output, contains('No bookmarks found.'));
    });

    test('displays empty message when data is null', () async {
      stubGetBookmarks(nullDataResponse());

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks']);

      expect(result.code, 0);
      expect(result.output, contains('No bookmarks found.'));
    });

    test('displays JSON output with --json flag', () async {
      stubGetBookmarks(bookmarksResponse());

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks', '--json']);

      expect(result.code, 0);
      // Should be valid JSON
      final parsed = jsonDecode(result.output);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"First bookmark"'));
    });

    test('--json output includes all bookmarks', () async {
      stubGetBookmarks(bookmarksResponse());

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks', '--json']);

      expect(result.output, contains('"100"'));
      expect(result.output, contains('"101"'));
      expect(result.output, contains('"102"'));
    });

    test('displays single bookmark correctly', () async {
      stubGetBookmarks(bookmarksResponse(tweets: [
        <String, dynamic>{
          'id': '200',
          'text': 'Only bookmark',
          'author_id': '20',
        },
      ]));

      final result =
          await runCapturing(runner, ['tweet', 'bookmarks']);

      expect(result.code, 0);
      expect(result.output, contains('[200]'));
      expect(result.output, contains('Only bookmark'));
      // Single bookmark should not have dividers
      expect(result.output, isNot(contains('---')));
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.getBookmarks(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const XApiException(500, 'Server error'));

      expect(
        () => runner.run(['tweet', 'bookmarks']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.getBookmarks(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'bookmarks']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('propagates auth exceptions', () async {
      when(() => mockApi.getBookmarks(
            paginationToken: any(named: 'paginationToken'),
          )).thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['tweet', 'bookmarks']),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
