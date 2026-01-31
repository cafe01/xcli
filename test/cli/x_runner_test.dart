import 'package:args/command_runner.dart';
import 'package:test/test.dart';
import 'package:xcli/src/cli/x_runner.dart';

void main() {
  late XCommandRunner runner;

  setUp(() {
    runner = XCommandRunner();
  });

  group('XCommandRunner', () {
    test('has correct name', () {
      expect(runner.executableName, 'x');
    });

    test('has description', () {
      expect(runner.description, isNotEmpty);
    });

    group('core commands', () {
      test('registers tweet command', () {
        expect(_findCommand(runner, 'tweet'), isNotNull);
      });

      test('registers timeline command', () {
        expect(_findCommand(runner, 'timeline'), isNotNull);
      });

      test('registers search command', () {
        expect(_findCommand(runner, 'search'), isNotNull);
      });

      test('registers user command', () {
        expect(_findCommand(runner, 'user'), isNotNull);
      });
    });

    group('additional commands', () {
      test('registers list command', () {
        expect(_findCommand(runner, 'list'), isNotNull);
      });

      test('registers dm command', () {
        expect(_findCommand(runner, 'dm'), isNotNull);
      });
    });

    group('plumbing commands', () {
      test('registers auth command', () {
        expect(_findCommand(runner, 'auth'), isNotNull);
      });

      test('registers config command', () {
        expect(_findCommand(runner, 'config'), isNotNull);
      });

      test('registers api command', () {
        expect(_findCommand(runner, 'api'), isNotNull);
      });
    });

    group('tweet subcommands', () {
      final expectedSubcommands = [
        'view',
        'create',
        'delete',
        'reply',
        'quote',
        'thread',
        'like',
        'unlike',
        'retweet',
        'unretweet',
        'bookmark',
        'bookmarks',
      ];

      for (final sub in expectedSubcommands) {
        test('has $sub subcommand', () {
          final tweet = _findCommand(runner, 'tweet')!;
          expect(tweet.subcommands.containsKey(sub), isTrue,
              reason: 'tweet should have "$sub" subcommand');
        });
      }
    });

    group('timeline subcommands', () {
      for (final sub in ['home', 'mentions', 'user']) {
        test('has $sub subcommand', () {
          final timeline = _findCommand(runner, 'timeline')!;
          expect(timeline.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('search subcommands', () {
      for (final sub in ['tweets', 'users']) {
        test('has $sub subcommand', () {
          final search = _findCommand(runner, 'search')!;
          expect(search.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('user subcommands', () {
      final expectedSubcommands = [
        'view',
        'me',
        'follow',
        'unfollow',
        'followers',
        'following',
        'block',
        'mute',
      ];

      for (final sub in expectedSubcommands) {
        test('has $sub subcommand', () {
          final user = _findCommand(runner, 'user')!;
          expect(user.subcommands.containsKey(sub), isTrue,
              reason: 'user should have "$sub" subcommand');
        });
      }
    });

    group('auth subcommands', () {
      for (final sub in ['login', 'logout', 'status', 'switch']) {
        test('has $sub subcommand', () {
          final auth = _findCommand(runner, 'auth')!;
          expect(auth.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('config subcommands', () {
      for (final sub in ['get', 'set', 'list']) {
        test('has $sub subcommand', () {
          final config = _findCommand(runner, 'config')!;
          expect(config.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('api command', () {
      test('accepts --method flag', () {
        final api = _findCommand(runner, 'api')!;
        expect(api.argParser.options.containsKey('method'), isTrue);
      });

      test('accepts --field flag', () {
        final api = _findCommand(runner, 'api')!;
        expect(api.argParser.options.containsKey('field'), isTrue);
      });

      test('accepts --paginate flag', () {
        final api = _findCommand(runner, 'api')!;
        expect(api.argParser.options.containsKey('paginate'), isTrue);
      });

      test('accepts --jq flag', () {
        final api = _findCommand(runner, 'api')!;
        expect(api.argParser.options.containsKey('jq'), isTrue);
      });
    });

    group('global flags', () {
      test('accepts --version', () {
        expect(runner.argParser.options.containsKey('version'), isTrue);
      });

      test('accepts --account', () {
        expect(runner.argParser.options.containsKey('account'), isTrue);
      });

      test('accepts --verbose', () {
        expect(runner.argParser.options.containsKey('verbose'), isTrue);
      });
    });
  });
}

Command<int>? _findCommand(CommandRunner<int> runner, String name) {
  return runner.commands[name];
}
