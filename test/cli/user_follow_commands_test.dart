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

  // ---------------------------------------------------------------
  // user follow
  // ---------------------------------------------------------------
  group('user follow', () {
    test('prints confirmation on success', () async {
      stubGetUser('alice', '100');
      when(() => mockApi.follow(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['user', 'follow', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('Followed @alice'));
    });

    test('resolves username to userId and calls follow', () async {
      stubGetUser('bob', '200');
      when(() => mockApi.follow(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['user', 'follow', 'bob']);

      verify(() => mockApi.getUser('bob')).called(1);
      verify(() => mockApi.follow('200')).called(1);
    });

    test('exits 64 when no username argument provided', () async {
      final result = await runCapturing(runner, ['user', 'follow']);

      expect(result.code, 64);
    });

    test('propagates API exceptions from getUser', () async {
      when(() => mockApi.getUser(any()))
          .thenThrow(const NotFoundException('User not found'));

      expect(
        () => runner.run(['user', 'follow', 'nonexistent']),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('propagates API exceptions from follow', () async {
      stubGetUser('carol', '300');
      when(() => mockApi.follow(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['user', 'follow', 'carol']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      stubGetUser('dave', '400');
      when(() => mockApi.follow(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['user', 'follow', 'dave']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  // ---------------------------------------------------------------
  // user unfollow
  // ---------------------------------------------------------------
  group('user unfollow', () {
    test('prints confirmation on success', () async {
      stubGetUser('alice', '100');
      when(() => mockApi.unfollow(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['user', 'unfollow', 'alice']);

      expect(result.code, 0);
      expect(result.output, contains('Unfollowed @alice'));
    });

    test('resolves username to userId and calls unfollow', () async {
      stubGetUser('bob', '200');
      when(() => mockApi.unfollow(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['user', 'unfollow', 'bob']);

      verify(() => mockApi.getUser('bob')).called(1);
      verify(() => mockApi.unfollow('200')).called(1);
    });

    test('exits 64 when no username argument provided', () async {
      final result = await runCapturing(runner, ['user', 'unfollow']);

      expect(result.code, 64);
    });

    test('propagates API exceptions from getUser', () async {
      when(() => mockApi.getUser(any()))
          .thenThrow(const NotFoundException('User not found'));

      expect(
        () => runner.run(['user', 'unfollow', 'nonexistent']),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('propagates API exceptions from unfollow', () async {
      stubGetUser('carol', '300');
      when(() => mockApi.unfollow(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['user', 'unfollow', 'carol']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      stubGetUser('dave', '400');
      when(() => mockApi.unfollow(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['user', 'unfollow', 'dave']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
