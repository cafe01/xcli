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

  /// Full API response for a user profile.
  Map<String, dynamic> userResponse({
    String id = '999',
    String username = 'testuser',
    String name = 'Test User',
    String? description = 'Building things.',
    bool verified = false,
    int followers = 1200,
    int following = 300,
    int tweets = 5000,
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

  void stubGetUser(Map<String, dynamic> response) {
    when(() => mockApi.getUser(any())).thenAnswer((_) async => response);
  }

  group('user view', () {
    test('displays human-readable output by default', () async {
      stubGetUser(userResponse());

      final result =
          await runCapturing(runner, ['user', 'view', 'testuser']);

      expect(result.code, 0);
      expect(result.output, contains('@testuser'));
      expect(result.output, contains('Test User'));
      expect(result.output, contains('Building things.'));
      expect(result.output, contains('1.2K Followers'));
      expect(result.output, contains('300 Following'));
      expect(result.output, contains('5K Tweets'));
    });

    test('displays JSON output with --json flag', () async {
      stubGetUser(userResponse(username: 'jsonuser'));

      final result =
          await runCapturing(runner, ['user', 'view', '--json', 'jsonuser']);

      expect(result.code, 0);
      expect(result.output, contains('"data"'));
      expect(result.output, contains('"jsonuser"'));
    });

    test('passes correct username to API', () async {
      stubGetUser(userResponse());

      await runCapturing(runner, ['user', 'view', 'elonmusk']);

      verify(() => mockApi.getUser('elonmusk')).called(1);
    });

    test('displays verified badge when verified', () async {
      stubGetUser(userResponse(verified: true));

      final result =
          await runCapturing(runner, ['user', 'view', 'testuser']);

      expect(result.code, 0);
      expect(result.output, contains('\u2713'));
    });

    test('does not display verified badge when not verified', () async {
      stubGetUser(userResponse(verified: false));

      final result =
          await runCapturing(runner, ['user', 'view', 'testuser']);

      expect(result.code, 0);
      expect(result.output, isNot(contains('\u2713')));
    });

    test('handles missing bio gracefully', () async {
      stubGetUser(userResponse(description: null));

      final result =
          await runCapturing(runner, ['user', 'view', 'testuser']);

      expect(result.code, 0);
      expect(result.output, contains('@testuser'));
      expect(result.output, contains('Test User'));
    });

    test('handles empty bio gracefully', () async {
      stubGetUser(<String, dynamic>{
        'data': <String, dynamic>{
          'id': '999',
          'username': 'testuser',
          'name': 'Test User',
          'description': '',
        },
      });

      final result =
          await runCapturing(runner, ['user', 'view', 'testuser']);

      expect(result.code, 0);
      expect(result.output, contains('@testuser'));
    });

    test('handles null data (user not found)', () async {
      stubGetUser(<String, dynamic>{'data': null});

      final result =
          await runCapturing(runner, ['user', 'view', 'nobody']);

      expect(result.code, 0);
      expect(result.output, contains('User not found'));
    });

    test('handles missing metrics gracefully', () async {
      stubGetUser(<String, dynamic>{
        'data': <String, dynamic>{
          'id': '999',
          'username': 'testuser',
          'name': 'Test User',
        },
      });

      final result =
          await runCapturing(runner, ['user', 'view', 'testuser']);

      expect(result.code, 0);
      expect(result.output, contains('@testuser'));
      expect(result.output, isNot(contains('Followers')));
    });

    test('exits 64 when no username argument provided', () async {
      final result = await runCapturing(runner, ['user', 'view']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.getUser(any()))
          .thenThrow(const NotFoundException('User not found'));

      expect(
        () => runner.run(['user', 'view', 'nobody']),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('propagates auth exceptions', () async {
      when(() => mockApi.getUser(any()))
          .thenThrow(const AuthException('Unauthorized'));

      expect(
        () => runner.run(['user', 'view', 'testuser']),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
