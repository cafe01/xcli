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

  group('tweet delete', () {
    test('prints confirmation on success', () async {
      when(() => mockApi.deleteTweet(any()))
          .thenAnswer((_) async {});

      final result =
          await runCapturing(runner, ['tweet', 'delete', '12345']);

      expect(result.code, 0);
      expect(result.output, contains('Deleted tweet 12345'));
    });

    test('calls API with correct tweet ID', () async {
      when(() => mockApi.deleteTweet(any()))
          .thenAnswer((_) async {});

      await runCapturing(runner, ['tweet', 'delete', '99']);

      verify(() => mockApi.deleteTweet('99')).called(1);
    });

    test('exits 64 when no ID argument provided', () async {
      final result = await runCapturing(runner, ['tweet', 'delete']);

      expect(result.code, 64);
    });

    test('propagates API exceptions', () async {
      when(() => mockApi.deleteTweet(any()))
          .thenThrow(const XApiException(403, 'Forbidden'));

      expect(
        () => runner.run(['tweet', 'delete', '123']),
        throwsA(isA<XApiException>()),
      );
    });

    test('propagates rate limit exceptions', () async {
      when(() => mockApi.deleteTweet(any()))
          .thenThrow(const RateLimitException('Rate limit exceeded'));

      expect(
        () => runner.run(['tweet', 'delete', '123']),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
