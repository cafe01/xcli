import 'package:args/command_runner.dart';

import 'commands/api/api_command.dart';
import 'commands/auth/auth_command.dart';
import 'commands/config/config_command.dart';
import 'commands/dm/dm_command.dart';
import 'commands/list/list_command.dart';
import 'commands/search/search_command.dart';
import 'commands/timeline/timeline_command.dart';
import 'commands/tweet/tweet_command.dart';
import 'commands/user/user_command.dart';

/// Top-level command runner for the X CLI.
///
/// Mirrors the X.com web/mobile experience as CLI subcommands.
/// Think `gh` for GitHub, but for X.com.
///
/// ```
/// x <command> [subcommand] [flags]
/// ```
class XCommandRunner extends CommandRunner<int> {
  XCommandRunner()
      : super(
          'x',
          'X.com CLI -- interact with X.com from the command line.',
        ) {
    // Core commands
    addCommand(TweetCommand());
    addCommand(TimelineCommand());
    addCommand(SearchCommand());
    addCommand(UserCommand());

    // Additional commands
    addCommand(ListCommand());
    addCommand(DmCommand());

    // Plumbing
    addCommand(AuthCommand());
    addCommand(ConfigCommand());
    addCommand(ApiCommand());

    // Global flags
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the x CLI version.',
    );
    argParser.addOption(
      'account',
      abbr: 'a',
      help: 'Use a specific authenticated account.',
    );
    argParser.addFlag(
      'verbose',
      negatable: false,
      help: 'Enable verbose output.',
    );
  }

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      final results = parse(args);

      if (results['version'] == true) {
        // ignore: avoid_print
        print('x version 0.1.0');
        return 0;
      }

      return await super.run(args);
    } on UsageException catch (e) {
      // ignore: avoid_print
      print(e.message);
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print(e.usage);
      return 64;
    }
  }
}
