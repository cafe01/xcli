import 'dart:io';

import 'package:args/command_runner.dart';

import '../api/raw_http_x_api.dart';
import '../api/x_api.dart';
import '../auth/authenticated_client.dart';
import '../auth/oauth_flow.dart';
import '../auth/token_store.dart';
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
  /// Creates the runner, optionally injecting an [XApi] for testing.
  XCommandRunner({XApi? api}) : _injectedApi = api, super(
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

  final XApi? _injectedApi;
  XApi? _defaultApi;

  /// The X API backend.
  ///
  /// Uses the injected API if provided; otherwise lazily constructs a
  /// [RawHttpXApi] backed by [AuthenticatedClient] with default config.
  XApi get api {
    if (_injectedApi != null) return _injectedApi;
    return _defaultApi ??= _buildDefaultApi();
  }

  XApi _buildDefaultApi() {
    final tokenStore = TokenStore();
    final clientId = Platform.environment['X_CLIENT_ID'] ?? '';
    final oauthFlow = OAuthFlow(clientId: clientId);
    final client = AuthenticatedClient(
      tokenStore: tokenStore,
      oauthFlow: oauthFlow,
    );
    return RawHttpXApi(client: client);
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
