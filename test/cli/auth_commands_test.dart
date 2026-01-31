import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:test/test.dart';
import 'package:xcli/src/auth/token.dart';
import 'package:xcli/src/auth/token_store.dart';
import 'package:xcli/src/cli/commands/auth/auth_command.dart';
import 'package:xcli/src/cli/x_runner.dart';

void main() {
  late Directory tempDir;
  late TokenStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('xcli_cmd_test_');
    store = TokenStore(configDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  OAuthToken makeToken({
    String accessToken = 'access-123',
    DateTime? expiresAt,
  }) =>
      OAuthToken(
        accessToken: accessToken,
        refreshToken: 'refresh-456',
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 2)),
        username: 'testuser',
        scopes: ['tweet.read', 'users.read'],
      );

  /// Create a test runner with injected auth dependencies.
  CommandRunner<int> testRunner(StringBuffer output) {
    final runner = CommandRunner<int>('x', 'test');
    runner.addCommand(AuthCommand(tokenStore: store, output: output));
    return runner;
  }

  group('auth command registration', () {
    test('XCommandRunner registers auth with all subcommands', () {
      final runner = XCommandRunner();
      final auth = runner.commands['auth']!;

      expect(auth.subcommands.containsKey('login'), isTrue);
      expect(auth.subcommands.containsKey('logout'), isTrue);
      expect(auth.subcommands.containsKey('status'), isTrue);
      expect(auth.subcommands.containsKey('switch'), isTrue);
    });

    test('login command has expected flags', () {
      final auth = AuthCommand(tokenStore: store);
      final login = auth.subcommands['login']!;
      final opts = login.argParser.options;

      expect(opts.containsKey('client-id'), isTrue);
      expect(opts.containsKey('port'), isTrue);
      expect(opts.containsKey('account'), isTrue);
      expect(opts.containsKey('no-browser'), isTrue);
      expect(opts.containsKey('scopes'), isTrue);
    });

    test('logout command has --all flag', () {
      final auth = AuthCommand(tokenStore: store);
      final logout = auth.subcommands['logout']!;

      expect(logout.argParser.options.containsKey('all'), isTrue);
    });

    test('switch command has correct invocation', () {
      final auth = AuthCommand(tokenStore: store);
      final switchCmd = auth.subcommands['switch']!;

      expect(switchCmd.invocation, contains('<account>'));
    });
  });

  group('auth status', () {
    test('shows "not logged in" when no accounts', () async {
      final output = StringBuffer();
      await testRunner(output).run(['auth', 'status']);

      expect(output.toString(), contains('Not logged in'));
    });

    test('shows active account with marker', () async {
      store.saveToken('mybot', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'status']);

      final text = output.toString();
      expect(text, contains('* mybot'));
      expect(text, contains('active'));
    });

    test('shows EXPIRED for expired tokens', () async {
      store.saveToken(
        'old-account',
        makeToken(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      );

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'status']);

      expect(output.toString(), contains('EXPIRED'));
    });

    test('shows multiple accounts', () async {
      store.saveToken('first', makeToken());
      store.saveToken('second', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'status']);

      final text = output.toString();
      expect(text, contains('first'));
      expect(text, contains('second'));
    });

    test('displays scopes', () async {
      store.saveToken('mybot', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'status']);

      expect(output.toString(), contains('tweet.read'));
    });

    test('displays config directory', () async {
      store.saveToken('mybot', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'status']);

      expect(output.toString(), contains(tempDir.path));
    });
  });

  group('auth logout', () {
    test('removes active account', () async {
      store.saveToken('mybot', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'logout']);

      expect(output.toString(), contains('Logged out'));
      expect(store.accounts, isEmpty);
    });

    test('reports nothing to logout when empty', () async {
      final output = StringBuffer();
      await testRunner(output).run(['auth', 'logout']);

      expect(output.toString(), contains('No active account'));
    });

    test('removes specific account by name', () async {
      store.saveToken('keep', makeToken());
      store.saveToken('remove', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'logout', 'remove']);

      expect(store.accounts, contains('keep'));
      expect(store.accounts, isNot(contains('remove')));
    });

    test('--all removes all accounts', () async {
      store.saveToken('one', makeToken());
      store.saveToken('two', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'logout', '--all']);

      expect(output.toString(), contains('2 account(s)'));
      expect(store.accounts, isEmpty);
    });

    test('returns error for unknown account', () async {
      final output = StringBuffer();
      final result = await testRunner(output).run(
        ['auth', 'logout', 'nonexistent'],
      );

      expect(result, 1);
      expect(output.toString(), contains('not found'));
    });
  });

  group('auth switch', () {
    test('switches active account', () async {
      store.saveToken('first', makeToken());
      store.saveToken('second', makeToken());

      final output = StringBuffer();
      await testRunner(output).run(['auth', 'switch', 'first']);

      expect(store.activeAccount, 'first');
      expect(output.toString(), contains('Switched'));
    });

    test('lists accounts when no argument given', () async {
      store.saveToken('alpha', makeToken());
      store.saveToken('beta', makeToken());

      final output = StringBuffer();
      final result = await testRunner(output).run(['auth', 'switch']);

      expect(result, 1);
      final text = output.toString();
      expect(text, contains('alpha'));
      expect(text, contains('beta'));
    });

    test('returns error for unknown account', () async {
      store.saveToken('known', makeToken());

      final output = StringBuffer();
      final result = await testRunner(output).run(
        ['auth', 'switch', 'unknown'],
      );

      expect(result, 1);
      expect(output.toString(), contains('not found'));
    });
  });

  group('auth login', () {
    test('requires client-id', () async {
      final output = StringBuffer();
      final result = await testRunner(output).run(['auth', 'login']);

      expect(result, 1);
      expect(output.toString(), contains('No client ID'));
      expect(output.toString(), contains('developer.x.com'));
    });
  });
}
