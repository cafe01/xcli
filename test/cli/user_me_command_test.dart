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

  /// Full API response for the authenticated user's profile.
  Map<String, dynamic> meResponse({
    String id = '42',
    String username = 'myuser',
    String name = 'My Name',
    String? description = 'I build things.',
    bool verified = true,
    int followers = 500,
    int following = 200,
    int tweets = 1500,
  }) =>
      <String, dynamic>{
        'data': <String, dynamic>{
          'id': id,
          'username': username,
          'name': name,
          if (description != null) 'description': description,
          'verified': verified,
          'public_metrics': <String, dynamic>{
            'followers_count': followers,
            'following_count': following,
            'tweet_count': tweets,
          },
        },
      };

  void stubGetMe(Map<String, dynamic> response) {
    when(() => mockApi.getMe()).thenAnswer((_) async => response);
  }

  group('user me', () {
    test('displays human-readable output by default', () async {
      stubGetMe(meResponse());

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.code, 0);
      expect(result.output, contains('@myuser'));
      expect(result.output, contains('My Name'));
      expect(result.output, contains('I build things.'));
      expect(result.output, contains('500 Followers'));
      expect(result.output, contains('200 Following'));
      expect(result.output, contains('1.5K Tweets'));
    });

    test('displays JSON output with --json flag', () async {
      stubGetMe(meResponse());

      final result = await runCapturing(runner, ['user', 'me', '--json']);

      expect(result.code, 0);
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"myuser"'));
    });

    test('calls getMe() with no arguments', () async {
      stubGetMe(meResponse());

      await runCapturing(runner, ['user', 'me']);

      verify(() => mockApi.getMe()).called(1);
    });

    test('displays verified badge when verified', () async {
      stubGetMe(meResponse(verified: true));

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.code, 0);
      expect(result.output, contains('\u2713'));
    });

    test('does not display verified badge when not verified', () async {
      stubGetMe(meResponse(verified: false));

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.code, 0);
      expect(result.output, isNot(contains('\u2713')));
    });

    test('handles missing bio gracefully', () async {
      stubGetMe(meResponse(description: null));

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.code, 0);
      expect(result.output, contains('@myuser'));
      expect(result.output, contains('My Name'));
    });

    test('handles null data gracefully', () async {
      stubGetMe(<String, dynamic>{'data': null});

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.code, 0);
      expect(result.output, contains('Could not retrieve profile'));
    });

    test('handles missing metrics gracefully', () async {
      stubGetMe(<String, dynamic>{
        'data': <String, dynamic>{
          'id': '42',
          'username': 'myuser',
          'name': 'My Name',
        },
      });

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.code, 0);
      expect(result.output, contains('@myuser'));
      expect(result.output, isNot(contains('Followers')));
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.getMe())
          .thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['user', 'me']),
        throwsA(isA<AuthException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.getMe())
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['user', 'me']),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('shows follower and following counts', () async {
      stubGetMe(meResponse(followers: 10000, following: 50));

      final result = await runCapturing(runner, ['user', 'me']);

      expect(result.output, contains('10K Followers'));
      expect(result.output, contains('50 Following'));
    });
  });
}
