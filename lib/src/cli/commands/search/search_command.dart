import 'package:args/command_runner.dart';

import 'search_tweets_command.dart';
import 'search_users_command.dart';

/// Parent command for search operations.
///
/// ```
/// x search tweets|users <query>
/// ```
class SearchCommand extends Command<int> {
  SearchCommand() {
    addSubcommand(SearchTweetsCommand());
    addSubcommand(SearchUsersCommand());
  }

  @override
  String get name => 'search';

  @override
  String get description => 'Search tweets and users.';
}
